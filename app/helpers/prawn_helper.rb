#NOTE : Intention is to make the styles and parts of the code reusable. But there is a lot more scope for improvment  -VBATTULA
module PrawnHelper
# module Prawn::Graphics

	def default_options 
		{
			:width => 250
		}
	end

	def dchbx_plan_header(data)
		@pdf.table(data, :width => @pdf.bounds.width) do
		  style(row(0), :border_color => '000000', :size => 10, :border_width => 0.5, :borders => [:top, :bottom])
		  style(row(0).column(0), :borders => [:left,:top, :bottom])
		  style(row(0).column(2), :borders => [:right,:top, :bottom])
		  style(columns(0), :font_style => :bold, :width => 125, )
		  style(columns(2), :width => 200, :align => :right)
		end
	end

	def dchbx_table_light_blue(data,position=25,options={})
		options=default_options.merge(options)
	  @pdf.table(data, :position => position, :width => options[:width]) do
      style(row(0..5).columns(0..1), :padding => [1, 5, 1, 5], :borders => [])
      style(row(0..5), :background_color => 'CDDDEE', :border_color => 'dddddd', :font_style => :bold)
      style(column(1), :align => :right)
    end
	end


	def dchbx_table_with_border(data,position=25,options={})
		options=default_options.merge(options)
	  @pdf.table(data, :position => position, :width => options[:width]) do
	      style(row(0..5).columns(0..1), :padding => [1, 5, 1, 5], :borders => [], :font_style => :bold,)
	      style(row(0), :font_style => :italic)
	      style(column(1), :align => :right)
	      style(row(0..5).column(0), :borders => [:left])
	      style(row(0..5).column(1), :borders => [:right])
	      style(row(5).column(0), :borders => [:left, :bottom])
	      style(row(5).column(1), :borders => [:right, :bottom])
	      style(row(0).column(0), :borders => [:left, :top])
	      style(row(0).column(1), :borders => [:right, :top])
    end
  end

  def stroke_dashed_horizontal_line(position=25,options={})
    @pdf.stroke do 
      @pdf.move_down 20
      @pdf.dash(5, space: 2, phase: 0)
      @pdf.horizontal_rule
    end
  end

  def dchbx_table_item_list(data,position=0,options={})
  	options=default_options.merge(options)
  	@pdf.table(data, :position=> position, :width => @pdf.bounds.width) do
      style(row(1..-1).columns(0..-1), :padding => [4, 5, 4, 5], :borders => [:bottom], :border_color => 'dddddd')
      style(row(0), :background_color => 'e9e9e9', :border_color => 'dddddd', :font_style => :bold)
      style(row(0).columns(0..-1), :borders => [:top, :bottom])
      style(row(0).columns(0), :borders => [:top, :left, :bottom])
      style(row(0).columns(-1), :borders => [:top, :right, :bottom])
      style(row(-1), :border_width => 2)
      style(column(1..-1), :align => :center)
      style(columns(0), :width => 270)
      style(columns(1), :width => 80)
    end
  end

  def dchbx_table_by_plan(data,position=0,options={})
    options=default_options.merge(options)
    @pdf.table(data, :position=> position, :width => @pdf.bounds.width) do
      style(row(1..-1).columns(0..-1), :size => 11, :padding => [4, 5, 4, 5], :borders => [:bottom], :border_color => 'dddddd')
      style(row(0), :background_color => 'e9e9e9', :border_color => 'dddddd', :font_style => :bold, :size => 11)
      style(row(0).columns(0..-1), :borders => [:top, :bottom])
      style(row(0).columns(0), :borders => [:top, :left, :bottom])
      style(row(0).columns(-1), :borders => [:top, :right, :bottom])
      style(row(-1), :border_width => 2)
      style(column(1..-1), :align => :center)
      style(columns(0), :width => 40)
      style(columns(1), :width => 60)
      style(columns(2), :width => 60)
      style(columns(3), :width => 60)
      style(columns(6), :width => 70)
    end
  end
end