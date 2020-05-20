require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require 'byebug'

module Markaby
  describe Builder do
    before do
      @builder = Markaby::Builder.new
    end

    context "internal state - ast" do
      it "should start off with empty ast" do
        @builder.ast.should == []
      end

      it "should be able to create a tag + set internal state" do
        @builder.tag(:foo)
        @builder.ast.should == [
          [:tag, :foo, {}]
        ]
      end

      it "should be able to create two tags in a row" do
        @builder.tag(:foo)
        @builder.tag(:bar)

        @builder.ast.should == [
          [:tag, :foo, {}],
          [:tag, :bar, {}]
        ]
      end

      it "should be able to nest tags" do
        @builder.tag(:foo) do
          @builder.tag(:bar)
        end

        @builder.ast.should == [
          [:tag, :foo, {}, [
            [:tag, :bar, {}]
          ]],
        ]
      end

      it "should be able to nest many tags" do
        @builder.tag(:foo) do
          @builder.tag(:bar)
        end

        @builder.ast.should == [
          [:tag, :foo, {}, [
            [:tag, :bar, {}]
          ]],
        ]
      end
    end

    context "compiling" do
      it "should be able to compile" do
        @builder.tag(:foo)

        # @builder.compile.should == "<foo></foo>"
        @builder.compile.should == [
          "<foo",
          ">",
          "</foo>",
        ]
      end

      it "should be able to delay compilation" do
        @builder.tag(:foo, {bar: 1})

        @builder.compile.should == [
          "<foo",
          " ",
          [:render_args, { bar: 1 }],
          ">",
          "</foo>",
        ]
        # @builder.compile.should == '<foo #{evaluate_args({:bar=>1})}></foo>'
        @builder.render.should == '<foo bar="1"></foo>'
      end

      it "should delay evaluation of arguments" do
        @builder.eval_code do
          tag(:foo, { bar: x })
        end

        @builder.compile.should == [
          "<foo",
          " ",
          [:render_args, '{ bar: x }'],
          ">",
          "</foo>",
        ]

        class << self
          attr_accessor :x
        end

        self.x = 10

        @builder.context = self

        # @builder.compile.should == '<foo #{evaluate_args({:bar=>1})}></foo>'
        @builder.render.should == '<foo bar="10"></foo>'
      end
    end


    # it "should be able to manage internal state" do
    #   @builder.div do
    #     @builder.blockquote do
    #     end
    #   end
    #
    #   @builder.ast.should == [
    #     [:tag, :div, {}, [
    #       [:tag, :blockquote, {}]
    #     ]],
    #
    #   ]
    # end

    # it "should be able to compile a tag" do
    #   @builder.div do
    #   end
    #
    #   @builder.compile.should == "<div></div>"
    # end
    #
    # it "should be able to compile the right tag" do
    #   @builder.blockquote do
    #   end
    #
    #   @builder.compile.should == "<blockquote></blockquote>"
    # end
    #
    # it "should be able to render after compiling" do
    #   @builder.blockquote do
    #   end
    #
    #   @builder.compile
    #   @builder.render.should == "<blockquote></blockquote>"
    # end
    #
    # it "should be able to nest tags" do
    #   @builder.div do
    #     @builder.blockquote do
    #     end
    #   end
    #
    #   @builder.compile.should == "<div><blockquote></blockquote></div>"
    # end
  end
end
