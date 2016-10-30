#!/usr/bin/env python

import argparse
import datetime
import jinja2
import json
import markdown
import markdown.inlinepatterns as mdpatterns
import os
import sys
import time


g_md = None
g_args = None


def cachekey(fpath):
  assert(fpath.startswith('/'))
  fpath = os.path.join(g_args.out_base_dir, fpath[1:])
  if not os.path.exists(fpath):
    print >>sys.stderr, '\033[91mLink not found: %s\033[0m' % fpath
  return '/' + os.path.relpath(os.path.realpath(fpath),
                               g_args.out_base_dir)

def mangleref(path):
  if '://' in path:
    return path
  if path.startswith('/'):
    return cachekey(path)
  return cachekey(g_args.resources_dir + '/' + path)


class ImgFilter(mdpatterns.ImagePattern):
  def handleMatch(self, m):
    node = mdpatterns.ImagePattern.handleMatch(self, m)
    src = node.attrib.get('src')
    if src:
      node.attrib['src'] = mangleref(src)
    return node


class LinkFilter(mdpatterns.LinkPattern):
  def handleMatch(self, m):
    node = mdpatterns.LinkPattern.handleMatch(self, m)
    href = node.attrib.get('href')
    if href:
      node.attrib['href'] = mangleref(href)
    return node


def main():
  global g_args
  global g_md
  parser = argparse.ArgumentParser()
  parser.add_argument('--template-in')
  parser.add_argument('--markdown-in', default=None)
  parser.add_argument('--markdown-meta-out', default=None)
  parser.add_argument('--json-in', action='append', default=[])
  parser.add_argument('--var', action='append', default=[])
  parser.add_argument('--html-out')
  parser.add_argument('--out-base-dir')
  parser.add_argument('--resources-dir')
  g_args = parser.parse_args()
  env = jinja2.Environment(loader=jinja2.FileSystemLoader('.'),
                           trim_blocks=True,
                           autoescape=True)
  env.filters['cachekey'] = cachekey

  variables = dict(var.split('=', 1) for var in g_args.var)
  variables['canonical_path'] = (
      '/' + os.path.relpath(os.path.realpath(g_args.html_out),
      g_args.out_base_dir)).replace('/index.html', '/')
  if g_args.markdown_in:
    variables['post_id'] = g_args.html_out.split('/')[-2]
    with open(g_args.markdown_in) as f:
      md_input = f.read()
    g_md = markdown.Markdown(
      extensions=['attr_list', 'codehilite', 'meta', 'toc'])
    g_md.inlinePatterns['image_link'] = ImgFilter(mdpatterns.IMAGE_LINK_RE, g_md)
    g_md.inlinePatterns['link'] = LinkFilter(mdpatterns.LINK_RE, g_md)
    rendered_html = g_md.convert(md_input.decode('utf-8'))
    for k,v in g_md.Meta.iteritems():
      variables[k] = v if k == 'tags' or len(v) > 1 else v[0]
    env.filters['noescape'] = lambda text: jinja2.Markup(text)
    if g_args.markdown_meta_out:
      with open(g_args.markdown_meta_out, 'w') as meta_fd:
        json.dump(variables, meta_fd, indent=4)
    variables['markdown_output'] = rendered_html

  for fname in g_args.json_in:
    with open(fname) as f:
      variables[os.path.basename(fname).replace('.','_')] = json.load(f)

  template = env.get_template(g_args.template_in)
  variables['strptime'] = lambda x:time.strptime(x, '%Y-%m-%d')
  variables['strftime'] = time.strftime
  variables['rfc3339time'] = datetime.datetime.now().isoformat('T') + 'Z'
  content = template.render(variables)
  with open(g_args.html_out + '.tmp', 'w') as f:
    f.write(content.encode('utf-8'))
  os.rename(g_args.html_out + '.tmp', g_args.html_out)

if __name__ == '__main__':
  main()
