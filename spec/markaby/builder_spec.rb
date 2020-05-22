require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require 'byebug'

module Markaby
  describe Builder do
    before do
      @builder = Markaby::Builder.new
    end

    context "internal state - stack" do
      it "should start off with empty stack" do
        @builder.stack.should == []
      end

      it "should be able to create a tag + set internal state" do
        @builder.tag(:foo)
        @builder.stack.should == [
          [:tag, :foo, nil]
        ]
      end

      it "should be able to create two tags in a row" do
        @builder.tag(:foo)
        @builder.tag(:bar)

        @builder.stack.should == [
          [:tag, :foo, nil],
          [:tag, :bar, nil]
        ]
      end

      it "should be able to nest tags" do
        @builder.tag(:foo) do
          @builder.tag(:bar)
        end

        @builder.stack.should == [
          [:tag, :foo, nil, [
            [:tag, :bar, nil]
          ]],
        ]
      end

      it "should be able to nest many tags" do
        @builder.tag(:foo) do
          @builder.tag(:bar)
        end

        @builder.stack.should == [
          [:tag, :foo, nil, [
            [:tag, :bar, nil]
          ]],
        ]
      end
    end

    context "compiling (and rendering)" do
      def array_compile_to_string(arrays)
        arrays.map do |key, value|
          value = value.to_s if value.is_a?(Markaby::Builder::AstRecompiled)

          [key, value]
        end
      end

      it "should be able to compile" do
        @builder.tag(:foo)

        # @builder.compile.should == "<foo></foo>"
        array_compile_to_string(@builder.compile).should == [
          [:text, "<foo"],
          [:text, ">"],
          [:text, "</foo>"],
        ]
      end

      it "should be able to delay compilation" do
        @builder.tag(:foo, {bar: 1})

        array_compile_to_string(@builder.compile).should == [
          [:text, "<foo"],
          [:text, " "],
          [:render_args, { bar: 1 }],
          [:text, ">"],
          [:text, "</foo>"],
        ]
        # @builder.compile.should == '<foo #{evaluate_args({:bar=>1})}></foo>'
        @builder.render.should == '<foo bar="1"></foo>'
      end

      it "should delay evaluation of arguments" do
        @builder.eval_code do
          tag(:foo, { bar: x })
        end

        array_compile_to_string(@builder.compile).should == [
          [:text, "<foo"],
          [:text, " "],
          [:render_args, '{ bar: x }'],
          [:text, ">"],
          [:text, "</foo>"],
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

    describe "rendering" do
      it "should be able to nest arguments" do
        @builder.eval_code do
          tag(:foo) do
            tag(:bar)
          end
        end

        @builder.render.should == "<foo><bar></bar></foo>"
      end

      it "should be able to nest many arguments deep" do
        @builder.eval_code do
          tag(:foo) do
            tag(:bar)
            tag(:bar) do
              tag(:baz)
            end
            tag(:quxx)
          end
        end

        @builder.render.should == "<foo><bar></bar><bar><baz></baz></bar><quxx></quxx></foo>"
      end

      it "should use nested argument values" do
        @builder.eval_code do
          tag(:foo) do
            tag(:bar)
            tag(:bar) do
              tag(:baz)
            end
            tag(:quxx)
          end
        end

        @builder.render.should == "<foo><bar></bar><bar><baz></baz></bar><quxx></quxx></foo>"
      end

      it "should compile only once" do
        @builder.eval_code do
          tag(:foo)
        end

        @builder.should_receive(:recursive_compile).once.and_return []

        @builder.render
        @builder.render
        @builder.render
      end

      it "should recompile when a tag is added" do
        @builder.eval_code do
          tag(:foo)
        end

        @builder.should_receive(:recursive_compile).twice.and_return []

        @builder.render
        @builder.eval_code do
          tag(:foo)
        end
        @builder.render
      end

      it "should be able to take a string and arguments" do
        @builder.tag(:foo, {bar: 1}, "something")
        @builder.render.should == "<foo bar=\"1\">something</foo>"
      end
    end
  end
end
