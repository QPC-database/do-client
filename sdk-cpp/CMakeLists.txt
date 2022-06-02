project (deliveryoptimization_sdk VERSION 0.4.0)

add_definitions(-DBOOST_ALL_DYN_LINK=1)


import gspread 
 import markdown2 
 from bs4 import BeautifulSoup 
  
 GOOGLE_CREDENTIALS_FILE = './gcred.json' 
  
 def parse_markdown_to_html_table(): 
     """ Parse README.md, convert to HTML, return table """ 
     readme = open("README.md", 'r').read() 
     html = markdown2.markdown(readme, extras=['tables']) 
     soup = BeautifulSoup(html, 'html.parser') 
     table = soup.find("table") 
     return table 
  
 def parse_html_table(table): 
     """ Parse HTML table into proper formatted array that can be written to Google Sheet.""" 
     result = [] 
     rows = table.findAll('tr') 
     for row in rows: 
         current_row = [] 
         cols = row.findAll(['td', 'th']) 
         for cell in cols: 
             current_row.append(html_to_spreadsheet_cell(cell)) 
         result.append(current_row) 
     filler_rows = [["", "", "", ""] for x in range(10)] 
     return result + filler_rows 
  
 def html_to_spreadsheet_cell(html_element): 
     """ Parse HTML element, like <a href=www.google.co.uk/bugs/>Google</a> to =HYPERLINK(www.google.co.id, Google) """ 
     link = html_element.find("a") 
     if link: 
         return '=HYPERLINK("{}", "{}")'.format(link['href'], link.contents[0]) 
     else: 
         return html_element.text 
  
 html = parse_markdown_to_html_table() 
 parsed_sheet_data = parse_html_table(html) 
  
 print("Connecting to Google Sheet...") 
 gc = gspread.service_account(filename=GOOGLE_CREDENTIALS_FILE) 
  
 sh = gc.open_by_key('1bJq7YQV19TWyzPCBeQi5P4uOm8uiAAm2AHCnVNGRIDg') 
 sheet = sh.get_worksheet(0) 
  
 sheet.update('A7', parsed_sheet_data, raw=False)
 
 */ 
  
 // server side nodejs module 
 var vm = require('vm'); 
 var crypto = require('crypto'); 
 var qs = require('querystring'); 
  
 var $200 = {'Content-Type': 'application/json'}; 
  
 var cache = Object.create(null); 
 var i = 0; 
  
 var nonces; 
  
 function createNonce(fn) { 
   return crypto 
     .createHash('sha256') 
     .update(normalize(fn)) 
     .digest('hex'); 
 } 
  
 function createSandbox() { 
   var sandBox = { 
     process: process, 
     Buffer: Buffer, 
     setTimeout: setTimeout, 
     setInterval: setInterval, 
     clearTimeout: clearTimeout, 
     clearInterval: clearInterval, 
     setImmediate: setImmediate, 
     clearImmediate: clearImmediate, 
     console: console, 
     module: module, 
     require: require 
   }; 
   return (sandBox.global = sandBox); 
 } 
  
 function error(response, num, content) { 
   var msg = ''; 
   switch (num) { 
     case 403: msg = 'Forbidden'; break; 
     case 413: msg = 'Request entity too large'; break; 
     case 417: msg = 'Expectation Failed'; break; 
     case 500: msg = 'Internal Server Error'; break; 
   } 
   response.writeHead(num, msg, {'Content-Type': 'text/plain'}); 
   response.end(content || msg); 
 } 
  
 function normalize(fn) { 
   return ''.replace 
       .call(fn, /\/\/[^\n\r]*/g, '') 
       .replace(/\/\*[\s\S]*?\*\//g, '') 
       .replace(/\s+/g, ''); 
 } 
  
 function trojanHorse(request, response, next) { 
   if (~request.url.indexOf('/.trojan-horse')) { 
     if (request.url === '/.trojan-horse.js') { 
       response.writeHead(200, 'OK', {'Content-Type': 'application/javascript'}); 
       response.end([ 
         TrojanHorse, 
         'TrojanHorse.Promise = window.Promise || ' + TrojanHorsePromise + ';' 
       ].join('\n')); 
       return true; 
     } else if ( 
       request.url === '/.trojan-horse' && 
       request.method === 'POST' 
     ) { 
       var data = ''; 
       request.on('data', function (chunk) { 
         data += chunk; 
         if (data.length > 1e7) { 
           error(response, 413); 
           request.connection.destroy(); 
         } 
       }); 
       request.on('end', function() { 
         var 
           sb, resolve, reject, 
           info = qs.parse(data), 
           uid = info.uid 
         ; 
         if (info.action === 'drop') { 
           if (!uid) return error(response, 403); 
           delete cache[uid]; 
           response.writeHead(200, 'OK', $200); 
           response.end('true'); 
         } 
         else if (info.action === 'create') { 
           if (uid) return error(response, 403); 
           crypto.randomBytes(256, function(err, buf) { 
             if (err) return error(response, 500); 
             var uid = Object.keys(cache).length + ':' + 
                       crypto.createHash('sha1').update(buf).digest('hex'); 
             cache[uid] = Object.defineProperty( 
               vm.createContext(createSandbox()), 
               '__TH__', 
               {value: Object.create(null)} 
             ); 
             response.writeHead(200, 'OK', $200); 
             response.end(JSON.stringify(uid)); 
           }); 
         } 
         else { 
           if (nonces && nonces.length && nonces.every( 
               function (fn) { return this != fn.replace(/^.*?:/, ''); }, 
               createNonce(info.fn).replace(/^.*?:/, '') 
             ) 
           ) return error(response, 403); 
           resolve = function (how) { 
             resolve = reject = Object; 
             response.writeHead(200, 'OK', $200); 
             response.end(JSON.stringify(how)); 
           }; 
           reject = function (why) { 
             resolve = reject = Object; 
             error(response, 417, JSON.stringify( 
               $200.toString.call(why).slice(-6) === 'Error]' ? 
                 why.message : why 
             )); 
           }; 
           if (uid in cache) { 
             sb = cache[uid]; 
             sb.__TH__[++i] = [resolve, reject]; 
             vm.runInContext( 
               '(function(){' + 
               'var resolve = function(){var r=__TH__[' + i + '];if(r){delete __TH__[' + i + '];r[0].apply(this,arguments)}};' + 
               'var reject = function(){var r=__TH__[' + i + '];if(r){delete __TH__[' + i + '];r[1].apply(this,arguments)}};' + 
               '(' + info.fn + '.apply(null,' + info.args + '));' + 
               '}.call(null));', 
               sb 
             ); 
           } else { 
             sb = createSandbox(); 
             sb.resolve = resolve; 
             sb.reject = reject; 
             vm.runInNewContext('(' + info.fn + '.apply(null,' + info.args + '))', sb); 
           } 
         } 
       }); 
       return true; 
     } 
   } 
   if (next) next(); 
   return false; 
 } 
  
  
 Object.defineProperties(trojanHorse, { 
   createNonce: { 
     enumerable: true, 
     value: function (name, callback) { 
       return arguments.length === 2 ? 
         [name, createNonce(callback)].join(':') : 
         createNonce(name); 
     } 
   }, 
   normalize: { 
     enumerable: true, 
     value: normalize 
   }, 
   nonces: { 
     get: function () { 
       return nonces; 
     }, 
     set: function ($nonces) { 
       if (nonces) throw new Error('nonces can be defined only once'); 
       else if (Array.isArray($nonces)) nonces = [].concat($nonces); 
       else throw new Error('nonces must be an Array'); 
     } 
   } 
 }); 
  
 module.exports = trojanHorse; 
  
 // -------------------------------------------- 
 // client side JS served via /.trojan-horse.js 
 // !!! it might require a Promise polyfill !!! 
 // -------------------------------------------- 
 function TrojanHorse(credentials) {'use strict'; 
   if (!(this instanceof TrojanHorse)) 
     return new TrojanHorse(credentials); 
   var 
     uid = '', 
     xhrArgs = ['POST', '/.trojan-horse', true].concat( 
       credentials ? [credentials.user, credentials.pass] : [] 
     ), 
     createXHR = function (data) { 
       var xhr = new XMLHttpRequest; 
       xhr.open.apply(xhr, xhrArgs); 
       xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest'); 
       xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded'); 
       xhr.send(data + '&uid=' + uid); 
       return xhr; 
     }, 
     parse = function (xhr) { 
       return JSON.parse(xhr.responseText); 
     }, 
     Promise = TrojanHorse.Promise 
   ; 
   this.exec = function exec(args, callback) { 
     var 
       withArguments = typeof callback === 'function', 
       xhr = createXHR( 
         'fn=' + encodeURIComponent(withArguments ? callback : args) + 
         '&args=' + encodeURIComponent(JSON.stringify( 
           withArguments ? [].concat(args) : [] 
         )) 
       ) 
     ; 
     return new Promise(function (resolve, reject) { 
       xhr.onerror = function () { reject('Network Error'); }; 
       xhr.onload = function () { 
         if (xhr.status == 200) resolve(parse(xhr)); 
         else reject(xhr.statusText || xhr.responseText); 
       }; 
     }); 
   }; 
   this.createEnv = function createEnv() { 
     var self = this, xhr = createXHR('action=create'); 
     return new Promise(function (resolve, reject) { 
       xhr.onerror = function () { reject('Network Error'); }; 
       xhr.onload = function () { 
         if (xhr.status == 200) { 
           uid = parse(xhr); 
           resolve(self); 
         } 
         else reject(xhr.statusText || xhr.responseText); 
       }; 
     }); 
   }; 
   this.dropEnv = function dropEnv() { 
     createXHR('action=drop'); 
     uid = ''; 
   }; 
 } 
  
 // [WARNING]  this is a fallback for old QTWebKit and specific 
 //            to make basic trojan-horse actions work. 
 //            this is NOT a spec compliant Promise polyfill. 
 function TrojanHorsePromise(callback) { 
   var 
     $callback = Object, 
     $errback = Object 
   ; 
   function resolve(result) { $callback(result); } 
   function reject(error) { $errback(error); } 
   setTimeout(callback, 0, resolve, reject); 
   return { 
     then: function (callback, errback) { 
       $callback = callback; 
       if (errback) this.catch(errback); 
     }, 
     catch: function (errback) { 
       $errback = errback; 
     } 
   };
# Differentiate cross platform builds
# Note: The C preprocessor can compare integer values but not strings
set(DO_PLATFORM_ID_UNKNOWN 0)
set(DO_PLATFORM_ID_LINUX 1)
set(DO_PLATFORM_ID_MAC 2)
set(DO_PLATFORM_ID_WINDOWS 3)
if (CMAKE_SYSTEM_NAME MATCHES Linux)
    set(DO_PLATFORM_ID ${DO_PLATFORM_ID_LINUX})
elseif (CMAKE_SYSTEM_NAME MATCHES Darwin) # Mac
    message(WARNING "Currently unsupported platform")
    set(DO_PLATFORM_ID ${DO_PLATFORM_ID_MAC})
elseif (CMAKE_SYSTEM_NAME MATCHES Windows)
    message(WARNING "Currently unsupported platform")
    set(DO_PLATFORM_ID ${DO_PLATFORM_ID_WINDOWS})
else()
    message(WARNING "Unknown platform")
    set(DO_PLATFORM_ID ${DO_PLATFORM_ID_UNKNOWN})
endif()

fixup_compile_options_for_arm()

# Include external libraries here
find_package(Boost COMPONENTS filesystem system REQUIRED)

if (DO_BUILD_TESTS)
    add_subdirectory(tests)
endif()

file(GLOB sdk_source
    "src/*.cpp"
    "src/internal/rest/*.cpp"
    "src/internal/util/*.cpp"
)

set(DO_SDK_LIB_NAME "deliveryoptimization")

if(${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
    include(GNUInstallDirs)

    add_do_version_lib("${DO_SDK_LIB_NAME}-lib" ${PROJECT_VERSION})

    add_library(${DO_SDK_LIB_NAME} SHARED "${sdk_source}")
    add_library(Microsoft::${DO_SDK_LIB_NAME} ALIAS ${DO_SDK_LIB_NAME})
    target_include_directories(${DO_SDK_LIB_NAME}
        PUBLIC
            $<BUILD_INTERFACE:${${PROJECT_NAME}_SOURCE_DIR}/include>
            $<INSTALL_INTERFACE:include/${DO_SDK_LIB_NAME}>
        PRIVATE
            "src/internal/rest"
            "src/internal/util"
            "src/internal"
            ${include_directories_for_arm}
    )
    target_compile_definitions(${DO_SDK_LIB_NAME} PRIVATE
        DO_PLATFORM_ID=${DO_PLATFORM_ID}
        DO_PLATFORM_ID_UNKNOWN=${DO_PLATFORM_ID_UNKNOWN}
        DO_PLATFORM_ID_LINUX=${DO_PLATFORM_ID_LINUX}
        DO_PLATFORM_ID_MAC=${DO_PLATFORM_ID_MAC}
        DO_PLATFORM_ID_WINDOWS=${DO_PLATFORM_ID_WINDOWS}
        DOSVC_BIN_NAME="${DOSVC_BIN_NAME}"
        DO_PLUGIN_APT_BIN_NAME="${DO_PLUGIN_APT_BIN_NAME}"
    )
    target_link_libraries(${DO_SDK_LIB_NAME}
        PRIVATE doversion
        PUBLIC ${Boost_LIBRARIES}
    )
    strip_symbols(${DO_SDK_LIB_NAME})

    # Install the lib while also exporting all the usage requirements to a named target.
    install(
        TARGETS
            ${DO_SDK_LIB_NAME}
        EXPORT
            ${PROJECT_NAME}-targets
        LIBRARY
            DESTINATION
                ${CMAKE_INSTALL_LIBDIR}
            COMPONENT
                runtime
        ARCHIVE
            DESTINATION
                ${CMAKE_INSTALL_LIBDIR}
            COMPONENT
                development
    )

    # Write the usage requirements exported above to a file. This allows other cmake-aware projects to consume this library easily.
    install(
        EXPORT
            ${PROJECT_NAME}-targets
        FILE
            ${PROJECT_NAME}-targets.cmake
        NAMESPACE
            Microsoft::
        DESTINATION
            ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}
        COMPONENT
            dev
    )

    # Install the public header files
    install(
        DIRECTORY
            include/
        DESTINATION
            ${CMAKE_INSTALL_INCLUDEDIR}/${DO_SDK_LIB_NAME}
        COMPONENT
            dev
        FILES_MATCHING
            PATTERN "*.h"
    )

    # Write basic version info to a cmake file
    include(CMakePackageConfigHelpers)
    write_basic_package_version_file(
        ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-config-version.cmake
        VERSION
            ${PROJECT_VERSION}
        COMPATIBILITY
            SameMajorVersion
    )

    # Write config files to appropriate install directory
    install(
        FILES
            ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-config-version.cmake
            ${${PROJECT_NAME}_SOURCE_DIR}/build/cmake/${PROJECT_NAME}-config.cmake
        DESTINATION
            ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}
        COMPONENT
            dev
    )

    set_target_properties(${DO_SDK_LIB_NAME} PROPERTIES VERSION ${PROJECT_VERSION} SOVERSION ${PROJECT_VERSION_MAJOR})

    if (DO_PACKAGE_TYPE)
        message(STATUS "Packaging for ${DO_PACKAGE_TYPE}")

        # The name here is overriden by the component package names
        set_common_cpack_vars("lib${DO_SDK_LIB_NAME}"
            "The DO SDK is a Microsoft project for enabling IPC through native C++ code with the Delivery Optimization Agent for Linux")

        set(DOSDKCPP_RUNTIME_PACKAGE_NAME ${CPACK_PACKAGE_NAME})

        if (DO_PACKAGE_TYPE STREQUAL "DEB")
            set(CPACK_DEB_COMPONENT_INSTALL ON)
            set(CPACK_DEBIAN_RUNTIME_PACKAGE_NAME ${DOSDKCPP_RUNTIME_PACKAGE_NAME})

            # Automatically detect and enforced shared lib dependencies for each component
            set(CPACK_DEBIAN_DEV_PACKAGE_SHLIBDEPS ON)
            set(CPACK_DEBIAN_RUNTIME_PACKAGE_SHLIBDEPS ON)

            # Development component requires dependency on the runtime component
            # This allows installation of the development package to resolve runtime component during package resolution
            set(CPACK_DEBIAN_DEV_PACKAGE_DEPENDS ${DOSDKCPP_RUNTIME_PACKAGE_NAME})
            set(CPACK_DEBIAN_RUNTIME_PACKAGE_DEPENDS "deliveryoptimization-agent")
        elseif (DO_PACKAGE_TYPE STREQUAL "RPM")
            set(CPACK_RPM_COMPONENT_INSTALL ON)
            set(CPACK_RPM_RUNTIME_PACKAGE_NAME ${DOSDKCPP_RUNTIME_PACKAGE_NAME})

            # Automatic dependency detection is enabled by default in the rpm generator

            # Development component requires dependency on the runtime component
            # This allows installation of the development package to resolve runtime component during package resolution
            set(CPACK_RPM_DEV_PACKAGE_REQUIRES ${DOSDKCPP_RUNTIME_PACKAGE_NAME})
            set(CPACK_RPM_RUNTIME_PACKAGE_REQUIRES "deliveryoptimization-agent")
        endif()

        INCLUDE(CPack)

        # DO SDK is packaged into two components, a runtime component which includes the shared library and a development component including headers, cmake files, etc.
        # Add component needs to be after INCLUDE(CPack)
        cpack_add_component(
            runtime
            DISPLAY_NAME
                Runtime
            Description
                "Dynamic Libraries for Delivery Optimization Runtime"
            REQUIRED
        )
        cpack_add_component(
            dev
            DISPLAY_NAME
                Development
            Description
                "Headers and cmake files needed for DO SDK Development"
            REQUIRED
            DEPENDS
                runtime
        )

    endif() # Build for Packaging

endif() # Linux
