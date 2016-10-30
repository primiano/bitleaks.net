var CANONICAL_HOST = 'https://www.bitleaks.net'

function LazyLoadJS(jsPath, onload)
{
  var js   = document.createElement('script');
  js.type  = 'text/javascript';
  js.async = true;
  js.src   = jsPath;
  js.setAttribute('data-timestamp', +new Date());
  if (onload)
    js.onload = onload;
  document.body.appendChild(js);
}

function initStickyTOC() {
  var post = document.getElementById('post');
  if (!post)
    return;

  var toc = document.getElementById('toc');
  var tocPlaceholder = document.getElementById('toc-placeholder');
  if (!toc || !tocPlaceholder)
    return;

  var tocState = 0;  // 0:invisible, 1:relative, 2:stick-top, 3:stick-bottom.
  var baseY = 0;
  var winHeight = 0;

  var headersY = [];
  var tocElements = [];
  var headersElements = post.getElementsByTagName('h2');
  for (var i = 0; i < headersElements.length; ++i) {
    var el = headersElements[i];
    headersY.push(el.offsetTop + el.offsetParent.offsetTop - el.clientHeight);
    var li = document.createElement('li');
    var link = document.createElement('a');
    link.href = '#' + el.id;
    link.innerHTML = el.innerHTML;
    li.appendChild(link);
    toc.getElementsByTagName('ul')[0].appendChild(li);
    tocElements.push(li);
  }

  var onResize = function() {
    baseY = tocPlaceholder.offsetTop + tocPlaceholder.offsetParent.offsetTop;
    winHeight = window.innerHeight;
    if (window.getComputedStyle(toc).visibility == 'hidden') {
      toc.classList.remove('ready');
      toc.classList.remove('visible');
      return;
    }
    toc.classList.add('ready');
    onScrollChange();
  };

  var onScrollChange = function() {
    if (!baseY)
      return;
    var y1 = window.scrollY;
    var y2 = y1 + window.innerHeight;

    var curTocElement = undefined;
    for (var i = 0; i < headersY.length; ++i) {
      var tocElement = tocElements[i];
      tocElement.classList.remove('active');
      if (y1 >= headersY[i])
        curTocElement = tocElement;
    }
    if (curTocElement)
      curTocElement.classList.add('active');

    if (y2 < baseY && tocState != 0) {
      toc.classList.remove('visible');
      toc.classList.remove('sticky-top');
      toc.classList.remove('sticky-bottom');
      tocState = 0;
    } else if (y2 >= baseY && y1 < baseY && tocState != 1) {
      toc.style.top = baseY + 'px';
      toc.classList.add('visible');
      toc.classList.remove('sticky-top');
      toc.classList.remove('sticky-bottom');
      tocState = 1;
    } else if (y1 >= baseY) {
      var reachedBottom = y1 + toc.clientHeight >= document.body.clientHeight;
      if (!reachedBottom && tocState != 2) {
        toc.style.top = '';
        toc.classList.add('visible');
        toc.classList.add('sticky-top');
        toc.classList.remove('sticky-bottom');
        tocState = 2;
      } else if (reachedBottom && tocState != 3) {
        toc.style.top = '';
        toc.classList.add('sticky-bottom');
        toc.classList.remove('sticky-top');
        tocState = 3;
      }
    }
  }  // onScrollChange;

  onResize();
  window.addEventListener('scroll', onScrollChange);
  window.addEventListener('resize', onResize);
}

function loadDisqus() {
  document.getElementById('disqus_thread').innerHTML = '';
  disqus_shortname = 'bitleaks';
  disqus_identifier = location.pathname;
  disqus_url = CANONICAL_HOST + window.location.pathname;
  LazyLoadJS('//' + disqus_shortname +'.disqus.com/embed.js');
}

function initDisqus() {
  var disqusDiv = document.getElementById('disqus_thread');
  if (!disqusDiv)
    return;
  var disqusY = disqusDiv.offsetTop + disqusDiv.offsetParent.offsetTop - 100;
  var isLoading = false;

  var onScrollChange = function() {
    if (window.scrollY + window.innerHeight >= disqusY && !isLoading) {
      setTimeout(loadDisqus, 0);
      isLoading = true;
      window.removeEventListener('scroll', onScrollChange);
    }

  }

  window.addEventListener('scroll', onScrollChange);
  onScrollChange();
}

initStickyTOC();
initDisqus();
