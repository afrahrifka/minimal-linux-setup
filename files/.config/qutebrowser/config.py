# Keep settings saved via :set, then apply the requested defaults.
config.load_autoconfig()
import catppuccin
catppuccin.setup(c, 'mocha', True)

c.url.searchengines = {'DEFAULT': 'https://www.google.com/search?q={}',
                       'g': 'https://www.google.com/search?q={}'}
c.url.start_pages = ['https://www.google.com/']
c.url.default_page = 'https://www.google.com/'
c.content.cookies.store = True

# Store/fill explicitly using the existing GNOME Keyring (one account per origin).
config.bind('ps', 'spawn --userscript keyring-login save')
config.bind('pf', 'spawn --userscript keyring-login fill')
config.bind('<Ctrl-Shift-p>', 'spawn --userscript keyring-login fill', mode='insert')

# Avoid accidentally closing a tab while typing in normal mode.
config.unbind('d', mode='normal')
config.bind('D', 'tab-close', mode='normal')

# Allow Google sign-in and reCAPTCHA resources, without clearing saved sessions.
for pattern in ('https://*.google.com/*', 'https://*.google.co.id/*',
                'https://*.gstatic.com/*', 'https://*.recaptcha.net/*'):
    config.set('content.blocking.enabled', False, pattern)
    config.set('content.javascript.enabled', True, pattern)
    config.set('content.cookies.accept', 'all', pattern)
