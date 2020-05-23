require 'parser/current'
require 'method_source'
require 'ast'
require 'unparser'

module Markaby
  class AstRecompiled
    def initialize(sexp)
      @sexp = sexp
      @string = Unparser.unparse(sexp)
    end

    def to_sexp
      @sexp
    end

    def to_s
      @string
    end
  end
end

module Markaby
  class Builder
    def initialize
      @stack = []
    end

    attr_reader :stack

    def eval_code(source = nil, &block)
      source_code = source || block.source

      parse_tree = Parser::CurrentRuby.parse(source_code)
      # skip the eval_code call (aka this method call)
      parse_tree = parse_tree.children[2]

      process_tree(parse_tree)
    end

    def text(str)
      @stack.push([:text, str])
    end

    def tag(name, *args, &block)
      the_text = args.last.is_a?(String) ? args.pop : nil
      options = args.any? ? args[0] : nil

      if the_text
        _tag(name, options) do
          text the_text
        end
      else
        _tag(name, options, &block)
      end
    end

    def _tag(name, options={}, &block)
      @compiled = false

      tag_stack = [:tag, name, options]
      @stack.push(tag_stack)

      if block_given?
        new_stack = []
        tag_stack.push(new_stack)

        old_ast = @stack
        @stack = new_stack

        yield if block_given?

        @stack = old_ast
      end
    end

    def compile
      @compiled ||= recursive_compile(@stack, [])
    end

    attr_accessor :context

    def render
      compile

      @compiled.map do |type, val|
        if type == :text
          val
        elsif type == :eval
          render_args(val)
        else
          raise "unknown?"
        end
      end.join("")
    end

  private

    def recursive_compile(stack, out)
      stack.map do |type, tag, options, subast|
        if type == :tag
          out << [:text, "<#{tag}"]

          if options
            out << [:text, " "]
            out << [:eval, options]
          end

          out << [:text, ">"]

          if subast
            subast.each do |ast|
              recursive_compile([ast], out)
            end
          end

          out << [:text, "</#{tag}>"]
        elsif type == :text
          out << [:text, tag]
        else
          raise "got here"
        end
      end

      out
    end

    def render_args(args={})
      if args.is_a?(AstRecompiled)
        result = context.instance_eval(args.to_s)
        render_args(result)
      elsif args.is_a?(Hash)
        args.map do |key, value|
          "#{key}=\"#{value}\""
        end.join(" ")
      else
        args
      end
    end

    def process_tree(sexp)
      type = sexp.type

      case type
      when :send
        receiver, method_name, *arguments = sexp.children

        if receiver == nil && method_name == :tag
          tag_name = arguments.shift
          tag_name = tag_name.to_sexp_array[1]

          args = arguments.map { |sexp| AstRecompiled.new(sexp) }
          tag(tag_name, *args)
        else
          eval_sexp sexp
        end
      else
        eval_sexp sexp
      end
    end

    def eval_sexp(sexp)
      eval(Unparser.unparse(sexp))
    end
  end
end
