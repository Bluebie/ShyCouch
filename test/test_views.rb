require 'test/unit'
require_relative '../lib/ShyCouch.rb'

class CouchViewTests < Test::Unit::TestCase
  JS_MAP_FUNCTION_HEADER = "function ( doc ) { \n    "
  JS_REDUCE_FUNCTION_HEADER = "function(key, values, rereduce)"
  JS_FUNCTION_FOOTER = "}"
  def setup
    @couch_views = []
  end
  
  def view(view_name, &block)
    @couch_views << ShyCouch::Data::View.new(view_name, &block)
  end
  def teardown; end
  
  def test_define_map_view
    view :five_star_butts do
      map do
        def function(doc)
          emit(doc) if doc.kind == "butt" and doc.star_rating == 5
        end
      end
    end
    expected_js = JS_MAP_FUNCTION_HEADER + %{if( doc.kind == "butt" && doc.star_rating == 5 ) {\n  emit(doc)\n} \n } + JS_FUNCTION_FOOTER
    assert_equal(expected_js, @couch_views[0].map)
    # puts @couch_views[0].map
  end
  
  def test_define_map_and_reduce_view
    view :beggar_count do
      map do
        def function(doc)
          emit(doc) if doc.kind == "beggar"
        end
      end
      reduce do
        def function(key, values, rereduce)
          return sum(values)
        end
      end
    end
    puts @couch_views[0].map
    puts @couch_views[0].reduce
    expected_map = JS_MAP_FUNCTION_HEADER + %{if( doc.kind == "beggar" ) {\n  emit(doc)\n} \n } + JS_FUNCTION_FOOTER
    expected_rejuce = JS_REDUCE_FUNCTION_HEADER
    assert_equal(expected_map, @couch_views[0].map)

  end
  
end