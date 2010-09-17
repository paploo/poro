module Poro
  module Util
    # = License
    #
    # Inflector is from AcitveSupport, which is distributed via the following
    # MIT license:
    #
    # Copyright (c) 2005-2010 David Heinemeier Hansson
    # 
    # Permission is hereby granted, free of charge, to any person obtaining
    # a copy of this software and associated documentation files (the
    # "Software"), to deal in the Software without restriction, including
    # without limitation the rights to use, copy, modify, merge, publish,
    # distribute, sublicense, and/or sell copies of the Software, and to
    # permit persons to whom the Software is furnished to do so, subject to
    # the following conditions:
    # 
    # The above copyright notice and this permission notice shall be
    # included in all copies or substantial portions of the Software.
    # 
    # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    # EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    # MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
    # NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
    # LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
    # OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
    # WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    #
    # = Overview
    #
    # This module contains the inflector from ActiveSupport, but in its own
    # namespace and without being injected into the String class.  This prevents
    # Poro's implementation from clobbering that of ActiveSupport, should the
    # rest of your project be using it, even if you include ActiveSupport before
    # Poro.
    module Inflector
      # Space intentionally left blank.
    end
  end
end

require 'poro/util/inflector/inflections'
require 'poro/util/inflector/methods'

module Poro
  module Util
    Inflector.inflections do |inflect|
      inflect.plural(/$/, 's')
      inflect.plural(/s$/i, 's')
      inflect.plural(/(ax|test)is$/i, '\1es')
      inflect.plural(/(octop|vir)us$/i, '\1i')
      inflect.plural(/(alias|status)$/i, '\1es')
      inflect.plural(/(bu)s$/i, '\1ses')
      inflect.plural(/(buffal|tomat)o$/i, '\1oes')
      inflect.plural(/([ti])um$/i, '\1a')
      inflect.plural(/sis$/i, 'ses')
      inflect.plural(/(?:([^f])fe|([lr])f)$/i, '\1\2ves')
      inflect.plural(/(hive)$/i, '\1s')
      inflect.plural(/([^aeiouy]|qu)y$/i, '\1ies')
      inflect.plural(/(x|ch|ss|sh)$/i, '\1es')
      inflect.plural(/(matr|vert|ind)(?:ix|ex)$/i, '\1ices')
      inflect.plural(/([m|l])ouse$/i, '\1ice')
      inflect.plural(/^(ox)$/i, '\1en')
      inflect.plural(/(quiz)$/i, '\1zes')

      inflect.singular(/s$/i, '')
      inflect.singular(/(n)ews$/i, '\1ews')
      inflect.singular(/([ti])a$/i, '\1um')
      inflect.singular(/((a)naly|(b)a|(d)iagno|(p)arenthe|(p)rogno|(s)ynop|(t)he)ses$/i, '\1\2sis')
      inflect.singular(/(^analy)ses$/i, '\1sis')
      inflect.singular(/([^f])ves$/i, '\1fe')
      inflect.singular(/(hive)s$/i, '\1')
      inflect.singular(/(tive)s$/i, '\1')
      inflect.singular(/([lr])ves$/i, '\1f')
      inflect.singular(/([^aeiouy]|qu)ies$/i, '\1y')
      inflect.singular(/(s)eries$/i, '\1eries')
      inflect.singular(/(m)ovies$/i, '\1ovie')
      inflect.singular(/(x|ch|ss|sh)es$/i, '\1')
      inflect.singular(/([m|l])ice$/i, '\1ouse')
      inflect.singular(/(bus)es$/i, '\1')
      inflect.singular(/(o)es$/i, '\1')
      inflect.singular(/(shoe)s$/i, '\1')
      inflect.singular(/(cris|ax|test)es$/i, '\1is')
      inflect.singular(/(octop|vir)i$/i, '\1us')
      inflect.singular(/(alias|status)es$/i, '\1')
      inflect.singular(/^(ox)en/i, '\1')
      inflect.singular(/(vert|ind)ices$/i, '\1ex')
      inflect.singular(/(matr)ices$/i, '\1ix')
      inflect.singular(/(quiz)zes$/i, '\1')
      inflect.singular(/(database)s$/i, '\1')

      inflect.irregular('person', 'people')
      inflect.irregular('man', 'men')
      inflect.irregular('child', 'children')
      inflect.irregular('sex', 'sexes')
      inflect.irregular('move', 'moves')
      inflect.irregular('cow', 'kine')

      inflect.uncountable(%w(equipment information rice money species series fish sheep jeans))
    end
  end
end

