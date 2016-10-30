import webapp2

class ChallengeHandler(webapp2.RequestHandler):
    def get(self, challenge):
        app = webapp2.get_app()
        response = app.registry.get(challenge)
        if not response:
          self.response.set_status(404)
          return
        self.response.headers['Content-Type'] = 'text/plain'
        self.response.write(response)

class ResponseHandler(webapp2.RequestHandler):
    def get(self, challenge, response):
        self.response.headers['Content-Type'] = 'text/plain'
        app = webapp2.get_app()
        app.registry[challenge] = response
        self.response.write('OK')

    def post(self, challenge, response):
      return self.get(challenge, response)

app = webapp2.WSGIApplication([
    ('/.well-known/acme-challenge/(.*)', ChallengeHandler),
    ('/.well-known/acme-response/([^/]+)/(.*)', ResponseHandler),
], debug=True)
