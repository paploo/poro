# Add the lib dir to the load path.
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
# Require the main require file.
require File.basename(File.expand_path(File.join(File.dirname(__FILE__),'..')))