list_modules.txt - list modules for install by composer
modules -- custom modules and patches, with inner structure
libraries -- libraries with inner structure
themes -- themes with inner sturcture
config_sync -- .yml files



-----------
## Changes
composer require  --with-all-dependencies 

### with "-" module will be deinstalled
drupal/responsive_image
drupal/breakpoint
drupal/views_slideshow
drupal/views_slideshow_cycle
-drupal/slick_views
-drupal/slick_extras
-drupal/slick_example
-drupal/slick_devel
-drupal/slick_ui
-drupal/slick


### unecessary configs list  list_deleted_config.txt
block.block.firma_modular_views_block__slideshow_block_1.yml
views.view.slideshow.yml


###########################################
-------------------------------------------




cp -R /data/sites_php82/modular.dev/config/sync/block.block.firma_modular_views_block__similar_products.yml /mnt/data/related_products/


cp -R /data/sites_php82/modular.dev/config/sync/block.block.firma_modular_views_block__similar_products.yml /mnt/data/related_products/


 cp /data/sites_php82/modular.dev/htdocs/themes/custom/firma_modular/css/dxpr_theme_subtheme.css  /mnt/data/related_products/
 
 
 ###
 
 cp /mnt/data/related_products/dxpr_theme_subtheme.css /data/sites_php82/modular.dev/htdocs/themes/custom/firma_modular/css/
 cp /mnt/data/related_products/block.view__related_products.yml /data/sites_php82/modular.dev/config/sync/
 cp /mnt/data/related_products/views.view.related_products.yml /data/sites_php82/modular.dev/config/sync/
 
 



