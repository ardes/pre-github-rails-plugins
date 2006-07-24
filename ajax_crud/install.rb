def link_to_rails(old_file, new_file)
  File.symlink(
    File.expand_path(File.join(File.dirname(__FILE__), old_file)),
    File.expand_path(File.join(File.expand_path(File.join(File.dirname(__FILE__), '../../..')), new_file)))
rescue
end
  
link_to_rails 'assets/javascripts/ardes_ajax_crud.js', 'public/javascripts/ardes_ajax_crud.js'
link_to_rails 'assets/stylesheets/ajax_crud.css',      'public/stylesheets/ajax_crud.css'

