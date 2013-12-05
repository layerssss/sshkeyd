`sshkeyd`是一个管理ssh key的小工具。

![image](https://f.cloud.github.com/assets/1559832/1616153/f1bba3dc-5605-11e3-8485-e5b7942bd7d0.png)

多服务器、多账户、多电脑的情况下管理ssh key有时蛮麻烦的。如果团队使用GitHub协作，又觉得`OpenLDAP`太笨重，那么可以尝试下这个`sshkeyd`工具。

配置使用极其简单：

- 不需要提交公钥，会自动从GitHub获取。
- 不需要写明团队里有那些成员，同样自动从GitHub的组织获取。
- 不用担心多台电脑、多服务器，`sshkeyd`会搞定。
- 你需要做的只是写明服务器的地址，剩下的都交给`sshkeyd`就好。
- 有web界面方便查看和管理。

安装
----

需要安装 `nodejs`, `git` (Mac下可使用`homebrew install nodejs git`)

```sh
sudo npm install sshkeyd -g
sshkeyd
```

打开浏览器访问  http://localhost:10000/


配置文件
---------

`~/.sshkeyd.json`。

许可
----

使用Copyright (c) 2013 Michael Yin

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.MIT许可

Copyright (c) 2013 Michael Yin

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

