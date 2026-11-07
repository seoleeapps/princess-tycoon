import base64, importlib.util, io, json, tempfile, unittest
from pathlib import Path
from unittest.mock import patch
from PIL import Image
spec=importlib.util.spec_from_file_location("generator",Path(__file__).with_name("generate.py"))
g=importlib.util.module_from_spec(spec);spec.loader.exec_module(g)

class GenerationSafety(unittest.TestCase):
    def test_unknown_submission_never_posts_again(self):
        with tempfile.TemporaryDirectory() as d:
            raw=Path(d);folder=raw/"hero";folder.mkdir()
            g.write(folder/"intent.json",{"reservation":10})
            with patch.object(g.api,"request",side_effect=AssertionError("duplicate request")) as request:
                with self.assertRaisesRegex(RuntimeError,"unknown"):
                    g.generate({"id":"hero","estimatedGenerations":10},{"maxGenerations":576},raw,"unused")
                request.assert_not_called()

    def test_budget_stops_before_submission(self):
        with tempfile.TemporaryDirectory() as d:
            raw=Path(d);folder=raw/"done";folder.mkdir()
            g.write(folder/"response.json",{"status":"completed","usage":{"type":"generations","generations":570}})
            with patch.object(g.api,"request",side_effect=AssertionError("over budget")) as request:
                with self.assertRaisesRegex(RuntimeError,"ceiling"):
                    g.generate({"id":"next","estimatedGenerations":10},{"maxGenerations":576},raw,"unused")
                request.assert_not_called()
                self.assertFalse((raw/"next/intent.json").exists())

    def test_resume_polls_original_id_without_post(self):
        with tempfile.TemporaryDirectory() as d:
            raw=Path(d);folder=raw/"hero";folder.mkdir()
            g.write(folder/"intent.json",{"reservation":10})
            g.write(folder/"submission.json",{"background_job_id":"existing-job"})
            buffer=io.BytesIO();Image.new("RGBA",(4,4),"red").save(buffer,format="PNG")
            result={"status":"completed","usage":{"generations":10},"last_response":{"images":[{"base64":base64.b64encode(buffer.getvalue()).decode()}]}}
            with patch.object(g.api,"request",return_value=result) as request:
                g.generate({"id":"hero"},{"maxGenerations":576},raw,"unused")
                request.assert_called_once_with("/background-jobs/existing-job","unused")
                self.assertTrue((folder/"variant-00.png").exists())
                self.assertEqual(g.committed_cost(raw),10)

    def test_failed_unknown_billing_keeps_reservation(self):
        with tempfile.TemporaryDirectory() as d:
            raw=Path(d);folder=raw/"hero";folder.mkdir()
            g.write(folder/"intent.json",{"reservation":10})
            g.write(folder/"response.json",{"status":"failed"})
            self.assertEqual(g.committed_cost(raw),10)


class TransportTests(unittest.TestCase):
    def test_http_errors_never_include_credential_or_response_body(self):
        import urllib.error
        import pixellab_transport
        error=urllib.error.HTTPError('https://api.pixellab.ai/v2/test',401,'secret-response',{},None)
        with patch('urllib.request.urlopen', side_effect=error) as send:
            with self.assertRaisesRegex(RuntimeError, '^PixelLab HTTP 401$'):
                pixellab_transport.request('/test','fake-credential',{'test':True})
            self.assertEqual(send.call_count,1)

    def test_missing_key_is_reported_without_environment_values(self):
        import pixellab_transport
        with patch.dict('os.environ',{},clear=True):
            with self.assertRaisesRegex(RuntimeError,'PIXELLAB_API_TOKEN is required'):
                pixellab_transport.token()

if __name__=='__main__':unittest.main()
