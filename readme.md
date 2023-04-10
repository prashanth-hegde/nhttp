# nhttp

A nvim plugin to make http calls right from nvim
http requests is a standard introduced by Intellij idea. More details can be found [here](https://www.jetbrains.com/help/idea/http-client-in-product-code-editor.html)
This plugin uses only neovim to issue http requests, obtain responses and process the output.

### install

install via any package manager:
```
'prashanth-hegde/nhttp'
```

### configurations

Here are the global configurations available to set

| config                       | default value | description                                                                                                                                                     |
| ----                         | -----         | -----                                                                                                                                                           |
| nttp_switch_to_output_window | false         | if true, when the output is returned, the cursor switches to the output window                                                                                  |
| nhttp_split                  | vertical      | valid options are `vertical` and `horozontal`. describes how output window should be split                                                                      |
| nhttp_env                    | prod          | see the environment config json example for reference                                                                                                           |
| nhttp_cmd                    | ""            | execute this command on the output window after getting the response, you can use jq, jpath or similar to format the output if needed. Use `?` as a placeholder |
| nhttp_config_file            | ""            | the configuration file path for json                                                                                                                            |

#### nhttp_switch_to_output_window
if true, when the output is returned, the cursor switches to the output window

#### nhttp_split
Available options are `vertical` and `horizontal`.
Configures how the output window is split relative to the open buffer.
If `vertial`, it opens the output window to the right,
if `horizontal`, it opens the output window at the bottom

#### nhttp_env
When there are secrets to be configured, or variables to be defined,
it could be defined as properties in json file and put it in a relative path
or an absolute path of the http file. check out the examples directory for more details

#### nhttp_cmd
This is a custom property that can be set by the user to perform post processing of the output
For instance, lets say you gor a compressed json as a result, you could perform post processing
on the json to format the json, map/filter by using something like `jq`, `jpath` or similar

If the output is text, you could set a custom `grep` or `awk` pattern to only show the lines you care about

In all cases, a special wildcard `?` is used to represent the output. For example, id you want to use `jq`
on a json output, you could the following to pretty print the output

`let nhttp_cmd = "jq . ?"`

#### nhttp_config_file
Per the

### todo

### references
1. [http client](https://www.jetbrains.com/help/idea/http-client-in-product-code-editor.html)
