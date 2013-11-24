sshkeyd
=======

manage ssh keys with ease

* you don't need to tell me public keys of yours & others, I can get them from your GitHub account.
* you don't need to tell me who's your teamates, I can get them from your GitHub organizations.
* you don't need to worry about other keys in server, I can pluck them out for you.
* all you need to do is tell me where is the server, and let me do the rest.
* bonus! teamates can also visit the dashboard and see which servers are authorized to them.

![image](https://f.cloud.github.com/assets/1559832/1616153/f1bba3dc-5605-11e3-8485-e5b7942bd7d0.png)

## Installation

* install `nodejs`, `git` (`homebrew install nodejs git`, maybe)
* `sudo npm install sshkeyd -g`
* `sshkeyd`
* open your browser and go to [http://localhost:10000/](http://localhost:10000/)

## Secrurity

`sshkeyd` only authorized access by keys retrieved from Github, not from user input. So don't worry, GitHub has taken care of your keys.

## Where is the configuration

It's at `~/.sshkeyd.json`, feel free to hack on it.

## License

The MIT License (MIT)

Copyright (c) 2013 Michael Yin

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
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

