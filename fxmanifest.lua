fx_version 'cerulean'
game 'gta5'

name 'spz-tutorial'
description 'SPiceZ first-time tour: opens every screen, spotlights it and explains it'
version '1.0.0'
author 'SPiceZ-Core'
lua54 'yes'

shared_scripts {
  '@ox_lib/init.lua',
}

client_scripts {
  'client/steps.lua',
  'client/main.lua',
}

ui_page 'ui/index.html'

files {
  'ui/index.html',
  'ui/style.css',
  'ui/app.js',
  'ui/fonts/*.ttf',
}

dependencies {
  'ox_lib',
  'spz-core',
}
