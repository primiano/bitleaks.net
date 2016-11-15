import webapp2

class RedirectToSiteRootHandler(webapp2.RequestHandler):
    def get(self):
      self.response.set_status(301)
      self.response.headers['Location'] = '/'

class AppendTrailingSlashHandler(webapp2.RequestHandler):
    def get(self, uri):
      self.response.set_status(301)
      redirect_uri = uri + '/'
      self.response.headers['Location'] = redirect_uri
      self.response.headers['Content-Type'] = 'text/plain'
      self.response.write(redirect_uri)

app = webapp2.WSGIApplication([
    ('/blog', RedirectToSiteRootHandler),
    ('/blog/', RedirectToSiteRootHandler),
    ('(.*[^/])', AppendTrailingSlashHandler),
], debug=True)
