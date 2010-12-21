#!/usr/bin/env ruby

#--

# Copyright 2003-2010 by Jim Weirich (jim.weirich@gmail.com)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.
#++

require 'rrake/version'

RAKEVERSION = Rake::VERSION

require 'rbconfig'
require 'fileutils'
require 'singleton'
require 'monitor'
require 'optparse'
require 'ostruct'

require 'rrake/ext/module'
require 'rrake/ext/string'
require 'rrake/ext/time'

require 'rrake/win32'

require 'rrake/task_argument_error'
require 'rrake/rule_recursion_overflow_error'
require 'rrake/rake_module'
require 'rrake/pseudo_status'
require 'rrake/task_arguments'
require 'rrake/invocation_chain'
require 'rrake/task'
require 'rrake/file_task'
require 'rrake/file_creation_task'
require 'rrake/multi_task'
require 'rrake/dsl_definition'
require 'rrake/file_utils_ext'
require 'rrake/file_list'
require 'rrake/default_loader'
require 'rrake/early_time'
require 'rrake/name_space'
require 'rrake/task_manager'
require 'rrake/application'
require 'rrake/environment'

$trace = false

# Alias FileList to be available at the top level.
FileList = Rake::FileList
