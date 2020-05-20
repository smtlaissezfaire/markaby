require 'parser/current'
require 'method_source'
require 'ast'
require 'unparser'

class AstProcessor
  include AST::Processor::Mixin
end

module Markaby
  class Builder

    def initialize
      @ast = []
    end

    attr_reader :ast

    def eval_code(source = nil, &block)
      source_code = source || block.source

      parse_tree = Parser::CurrentRuby.parse(source_code)
      # skip the eval_code call (aka this method call)
      parse_tree = parse_tree.children[2]

      process_tree(parse_tree)
    end

    def process_tree(sexp)
      type = sexp.type

      case type
      when :send
        receiver, method_name, *arguments = sexp.children
        if receiver == nil && method_name == :tag
          tag_name = arguments.shift
          tag_name = tag_name.to_sexp_array[1]

          args = Unparser.unparse(arguments[0])
          puts "calling tag with args: #{args}"
          tag(tag_name, args)
        else
          eval(Unparser.unparse(sexp))
        end
      else
        eval(Unparser.unparse(sexp))
      end
    end

    def tag(name, options={}, &block)
      tag_stack = [:tag, name, options]
      @ast.push(tag_stack)

      if block_given?
        new_stack = []
        tag_stack.push(new_stack)

        old_ast = @ast
        @ast = new_stack

        yield

        @ast = old_ast
      end
    end

    def compile(ast = @ast, out = [])
      ast.map do |type, tag, options, subast|
        out << "<#{tag}"

        if !options.empty?
          out << " "
          out << [:render_args, options]
        end

        out << ">"
        out << "</#{tag}>"
      end

      out
    end

    attr_accessor :context

    def render_args(args={})
      if args.is_a?(String)
        result = context.instance_eval(args)
        render_args(result)
      else
        args.map do |key, value|
          "#{key}=\"#{value}\""
        end.join(" ")
      end
    end

    def render
      @compiled = compile

      @compiled.map do |compiled|
        if compiled.is_a?(String)
          compiled
        else
          render_args(compiled[1])
        end
      end.join("")
    end

    # def div(&block)
    #   tag("div", {}, &block)
    # end
    #
    # def blockquote(&block)
    #   tag("blockquote", {}, &block)
    # end
    #
    #
    # def render
    #   compile
    # end
  end
end
