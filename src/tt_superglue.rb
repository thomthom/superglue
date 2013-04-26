#-------------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-------------------------------------------------------------------------------

require 'sketchup.rb'
require 'extensions.rb'

#-------------------------------------------------------------------------------

module TT
 module Plugins
  module SuperGlue
  
  ### CONSTANTS ### ------------------------------------------------------------
  
  # Plugin information
  PLUGIN_ID       = 'TT_SuperGlue'.freeze
  PLUGIN_NAME     = 'SuperGlue'.freeze
  PLUGIN_VERSION  = '1.3.0'.freeze
  
  # Resource paths
  FILENAMESPACE = File.basename( __FILE__, '.rb' )
  PATH_ROOT     = File.dirname( __FILE__ ).freeze
  PATH          = File.join( PATH_ROOT, FILENAMESPACE ).freeze
  PATH_ICONS    = File.join( PATH, 'icons' ).freeze
  PATH_CURSORS  = File.join( PATH, 'cursors' ).freeze
  
  
  ### EXTENSION ### ------------------------------------------------------------
  
  unless file_loaded?( __FILE__ )
    loader = File.join( PATH, 'core.rb' )
    ex = SketchupExtension.new( PLUGIN_NAME, loader )
    ex.description = 'Re-attach or detach glue-to components.'
    ex.version     = PLUGIN_VERSION
    ex.copyright   = 'Thomas Thomassen © 2010-2013'
    ex.creator     = 'Thomas Thomassen (thomas@thomthom.net)'
    Sketchup.register_extension( ex, true )
  end
  
  end # module SuperGlue
 end # module Plugins
end # module TT

#-------------------------------------------------------------------------------

file_loaded( __FILE__ )

#-------------------------------------------------------------------------------