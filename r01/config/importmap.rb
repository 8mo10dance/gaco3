# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"
pin "alpinejs", to: "https://ga.jspm.io/npm:alpinejs@3.13.2/dist/module.esm.js"
pin "qs", to: "https://ga.jspm.io/npm:qs@6.11.2/lib/index.js"
pin "#util.inspect.js", to: "https://ga.jspm.io/npm:@jspm/core@2.0.1/nodelibs/@empty.js"
pin "call-bind/callBound", to: "https://ga.jspm.io/npm:call-bind@1.0.5/callBound.js"
pin "define-data-property", to: "https://ga.jspm.io/npm:define-data-property@1.1.1/index.js"
pin "function-bind", to: "https://ga.jspm.io/npm:function-bind@1.1.2/index.js"
pin "get-intrinsic", to: "https://ga.jspm.io/npm:get-intrinsic@1.2.2/index.js"
pin "gopd", to: "https://ga.jspm.io/npm:gopd@1.0.1/index.js"
pin "has-property-descriptors", to: "https://ga.jspm.io/npm:has-property-descriptors@1.0.1/index.js"
pin "has-proto", to: "https://ga.jspm.io/npm:has-proto@1.0.1/index.js"
pin "has-symbols", to: "https://ga.jspm.io/npm:has-symbols@1.0.3/index.js"
pin "hasown", to: "https://ga.jspm.io/npm:hasown@2.0.0/index.js"
pin "object-inspect", to: "https://ga.jspm.io/npm:object-inspect@1.13.1/index.js"
pin "set-function-length", to: "https://ga.jspm.io/npm:set-function-length@1.1.1/index.js"
pin "side-channel", to: "https://ga.jspm.io/npm:side-channel@1.0.4/index.js"
