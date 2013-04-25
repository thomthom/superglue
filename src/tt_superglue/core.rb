#-------------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-------------------------------------------------------------------------------

require 'sketchup.rb'
begin
  require 'TT_Lib2/core.rb'
rescue LoadError => e
  module TT
    if @lib2_update.nil?
      url = 'http://www.thomthom.net/software/sketchup/tt_lib2/errors/not-installed'
      options = {
        :dialog_title => 'TT_Lib² Not Installed',
        :scrollable => false, :resizable => false, :left => 200, :top => 200
      }
      w = UI::WebDialog.new( options )
      w.set_size( 500, 300 )
      w.set_url( "#{url}?plugin=#{File.basename( __FILE__ )}" )
      w.show
      @lib2_update = w
    end
  end
end


#-------------------------------------------------------------------------------

if defined?( TT::Lib ) && TT::Lib.compatible?( '2.7.0', 'SuperGlue' )

module TT::Plugins::SuperGlue

  ### MENU & TOOLBARS ### ------------------------------------------------------
  
  unless file_loaded?( __FILE__ )
    # Menus
    m = TT.menu( 'Tools' )
    m.add_item( 'Superglue' )   { self.select_tool( SuperGlueTool ) }
  end 
  
  
  ### MAIN SCRIPT ### ----------------------------------------------------------
  
  # @since 1.0.0
  def self.select_tool(tool)
    Sketchup.active_model.tools.push_tool( tool.new )
  end
  
  
  # @since 1.0.0
  class SuperGlueTool
    
    SUPERGLUE = 0
    SOLVENT = 1
    
    # @since 1.0.0
    def initialize
      # Icon: http://mattahan.deviantart.com/art/Buuf-37966044?q=boost%3Apopular+buuf+icon&qo=0
      #       Paul Davey aka Mattahan. All rights reserved. 
      cursor_superglue = File.join( PATH_ICONS, 'Superglue.png')
      cursor_solvent   = File.join( PATH_ICONS, 'Solvent.png')
      @cursor_superglue = UI.create_cursor(cursor_superglue,  15, 0)
      @cursor_solvent   = UI.create_cursor(cursor_solvent,    15, 0)
      
      @mode = SUPERGLUE
      @colour = [255,192,0]
    end
    
    # @since 1.0.0
    def onSetCursor
      if @mode == SUPERGLUE
        UI.set_cursor(@cursor_superglue)
      else
        UI.set_cursor(@cursor_solvent)
      end
    end
    
    # @since 1.0.0
    def updateUI
      if @mode == SUPERGLUE
        Sketchup.status_text = 'Superglue - sweep across components to glue them to the face they lie on. Press Ctrl to switch to Solvent.'
      else
        Sketchup.status_text = 'Solvent - sweep across components to unglue them. Press Ctrl to switch to Superglue.'
      end
    end
    
    # @since 1.0.0
    def activate
      @path = []
      @face = nil
      @bp = nil
      @ap = nil
      updateUI()
    end
    
    # @since 1.0.0
    def deactivate(view)
      view.invalidate
    end
    
    # @since 1.0.0
    def resume(view)
      updateUI()
    end
    
    # @since 1.0.0
    def onKeyUp(key, repeat, flags, view)
      if key == COPY_MODIFIER_KEY
        if @mode == SUPERGLUE 
          @mode = SOLVENT
        else
          @mode = SUPERGLUE
        end
        onLButtonUp(flags, 0, 0, view)
        onSetCursor()
        updateUI()
      end
    end
    
    # @since 1.0.0
    def onLButtonDown(flags, x, y, view)
      @flags = flags
      @path.clear
      
      operation_name = (@mode == SUPERGLUE) ? 'Superglue' : 'Solvent'
      view.model.start_operation(operation_name)
      view.invalidate
    end

    # @since 1.0.0
    def onMouseMove(flags, x, y, view)
      @flags = flags
      if flags & MK_LBUTTON == MK_LBUTTON
        @path << Geom::Point3d.new(x, y, 0)
        
        ph = view.pick_helper
        ph.do_pick(x, y)
        
        @bp = ph.best_picked
        @ap = ph.all_picked
        
        # sub-class MUST implement this
        if @mode == SUPERGLUE
          onSqueezeGlue(flags, x, y, view, ph)
        else
          onSqueezeSolvent(flags, x, y, view, ph)
        end
      end
      view.invalidate
    end
    
    # @since 1.0.0
    def onLButtonUp(flags, x, y, view)
      @flags = flags
      @path.clear
      view.model.commit_operation
      view.invalidate
    end
    
    # @since 1.0.0
    def onSqueezeGlue(flags, x, y, view, ph)
      if ph.picked_face && ph.all_picked.include?( ph.picked_face )
        @face = ph.picked_face
        
        view.model.selection.clear
        view.model.selection.add( @face )
      end
      
      if @bp.nil?
        @face = nil
      end
      
      if @face && @bp.respond_to?( :glued_to )
        dfn = @bp.definition
        if dfn.behavior.is2d? &&
           @bp.transformation.zaxis.samedirection?( @face.normal ) &&
           @face.classify_point( @bp.transformation.origin ) <= 8
              @bp.glued_to = @face
        end
      end
    end
    
    # @since 1.0.0
    def onSqueezeSolvent(flags, x, y, view, ph)
      if @bp && @bp.respond_to?( :glued_to ) && @bp.glued_to
        @bp.glued_to = nil
      end
    end
    
    # @since 1.0.0
    def draw(view)
      #view.draw_text( [100,50,0], "onMouseMove flags: #{@flags}" )
      #view.draw_text( [100,70,0], "@face: #{@face}" )
      #view.draw_text( [100,90,0], "@bp: #{@bp}" )
      #view.draw_text( [100,110,0], "@ap: #{@ap}" )
      if @path.size > 1
        view.line_stipple = ''
        view.line_width = 5
        view.drawing_color = (@mode == SUPERGLUE) ? [255,192,0] : [128,192,255]
        view.draw2d(GL_LINE_STRIP, @path)
        #view.draw_points(@path, 20, 4, [255,0,0])
      end
    end
    
  end # class SuperGlueTool

  
  ### DEBUG ### ----------------------------------------------------------------
  
  # @note Debug method to reload the plugin.
  #
  # @example
  #   TT::Plugins::SuperGlue.reload
  #
  # @param [Boolean] tt_lib Reloads TT_Lib2 if +true+.
  #
  # @return [Integer] Number of files reloaded.
  # @since 1.0.0
  def self.reload( tt_lib = false )
    original_verbose = $VERBOSE
    $VERBOSE = nil
    TT::Lib.reload if tt_lib
    # Core file (this)
    load __FILE__
    # Supporting files
    if defined?( PATH ) && File.exist?( PATH )
      x = Dir.glob( File.join(PATH, '*.{rb,rbs}') ).each { |file|
        load file
      }
      x.length + 1
    else
      1
    end
  ensure
    $VERBOSE = original_verbose
  end

end # module

end # if TT_Lib

#-------------------------------------------------------------------------------

file_loaded( __FILE__ )

#-------------------------------------------------------------------------------