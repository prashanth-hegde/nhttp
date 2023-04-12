# nhttp

nhttp stands for neovim-http

A nvim plugin to make http calls right from nvim
http requests is a standard introduced by Intellij idea. More details can be found [here](https://www.jetbrains.com/help/idea/http-client-in-product-code-editor.html)
This plugin uses only neovim to issue http requests, obtain responses and process the output.

### pre-requisites
The plugin uses `curl` to make http calls. There are no other pre-requisites to installing and running the plugin.
Just ensure curl is installed and available in the path.
Also, if `nhttp_cmd` is configured, that application also needs to be available in the path

### install

install via any neovim package manager:
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

If the output is text, you could set a custom `grep` or `awk` pattern to only show the lines you care about.
If this option is not configured, the output rendered as-is and no post-processing is done.

In all cases, a special wildcard `?` is used to represent the output. For example, id you want to use `jq`
on a json output, you could the following to pretty print the output

`let nhttp_cmd = "jq . ?"`

#### nhttp_config_file
Per the http documentation, it is mentioned that the environment configuration is specified as `http-client.env.json`.

`nhttp` lets the user to override this config file to be present anywhere. If an absolute path is not provided,
the config file is assumed to be relative to the file that is being operated upon.
Also the config file is only needed if there are any variables present in the http file. If there are no variables,
neither the config is needed nor the file is needed to be configured

#### example configuration

```lua
vim.g["nhttp_cmd"] = "jpath . ?"
vim.g["nhttp_switch_to_output_window"] = "false"
```

**recommended settings**
The file extension `.http` is not readily recognized by vim. It is identified as a config file.
In order to properly treat it and issue keyboard shortcuts, you can make small tweaks to the
startup to readily recognize the file and use keyboard shortcuts to trigger an http request

```lua
-- nhttp execute on <CR> key
vim.api.nvim_create_autocmd("FileType", {
  pattern = 'conf',
  callback = function()
    vim.keymap.set('n', '<CR>', '<CMD>NHttp<CR>', {buffer=true})
  end,
})
```

#### override global configuration
One way to configure variables is via vim global variables as shown.
However, if the user wants to override the global variables with file specific variables,
it can be achieved via setting the variable within the file at the top. This is a
nhttp specific feature, and not related to Intellij

### commands

#### NHttp
This is the executor command - It parses the request under the cursor and issues a `curl` request,
and renders the response in the output buffer. For easy trigger, this command can be mapped
to a keystroke if needed

#### NHttpCmd
This command takes the request under the cursor and generates the curl command and displays
the curl command in the output window

#### NHttpCopy
This command copies the generated curl command under the cursor and puts it in the register '*'
Meaning, the clipboard contents now has the `curl` command from the request in the cursor section

### todo
* graphql support
* convert to 100% lua based, no vimscript
* the time taken metric has a bug in it, needs to be fixed


### references
1. [http client](https://www.jetbrains.com/help/idea/http-client-in-product-code-editor.html)
1. [jpath](https://github.com/prashanth-hegde/jpath)
