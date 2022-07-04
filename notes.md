# Chaincode Labs Seminar – Exercises for Bitcoin Protocol Development


## Using Docker
```bash
$ vi Dockerfile
```

```docker
FROM debian:bullseye

RUN apt-get update \
	&& apt-get install --yes --no-install-recommends \
		ca-certificates \
		wget \
		gnupg \
	&& apt-get install --yes \
		bash-completion \
		curl \
		git \
		vim \
	&& apt-get clean \
	&& rm -rf \
		/var/lib/apt/lists/* \
		/tmp/* \
		/var/tmp/*
```

```bash
# build Docker container
$ docker build -t bpd ./
# list Docker images
$ docker image ls
# list Docker containers
$ docker container ls -a
# run Docker container
$ docker run -it bpd
# start Docker container
$ docker start $containerIdOrName
# Bash into Docker container
$ docker exec -it $containerIdOrName bash
```


## Task 1: Compile Bitcoin Core

>  Compile Bitcoin Core (https://github.com/bitcoin/bitcoin). You can see doc/build-*.md for instructions on building the various elements.


### Autogen
```bash
$ sudo apt-get install --yes autoconf libtool pkg-config
$ cd /tmp/
$ git clone 'https://github.com/bitcoin/bitcoin'
$ cd bitcoin/
$ ./autogen.sh 2>&1 | tee autogen.sh.log
```


### Configure
```bash
$ sudo apt-get install --yes bsdmainutils build-essential gettext libboost1.74-dev libevent-dev libsqlite3-dev libzmq3-dev qttools5-dev-tools
# Without BDB 4.
# (Skip this if you want to have BDB 4 and continue with the next point.)
./configure 2>&1 | tee configure.log

# With BDB 4.
# Must specify a single argument: the directory in which db4 will be built.
# This is probably `pwd` if you're at the root of the bitcoin repository.
./contrib/install_db4.sh "$(pwd)" 2>&1 | tee install_db4.sh.log
export BDB_PREFIX='/tmp/bitcoin/db4'
./configure BDB_LIBS="-L${BDB_PREFIX}/lib -ldb_cxx-4.8" BDB_CFLAGS="-I${BDB_PREFIX}/include" 2>&1 | tee configure.log
```


### Make
```bash
$ export JOBS_NUMBER=12
$ time make -j "${JOBS_NUMBER}" 2>&1 | tee make.log
```


### Make install
```bash
$ make install 2>&1 | tee make-install.log
```


### Copying relevant output files
```bash
$ docker commit -m 'Task 1 solved.' $containerIdOrName bpd:task1
$ docker cp $containerIdOrName:/tmp/bitcoin/autogen.sh.log .
$ docker cp $containerIdOrName:/tmp/bitcoin/install_db4.sh.log .
$ docker cp $containerIdOrName:/tmp/bitcoin/configure.log .
$ docker cp $containerIdOrName:/tmp/bitcoin/make.log .
$ docker cp $containerIdOrName:/tmp/bitcoin/make-install.log .
```


### Problems & Solutions

* LRELEASE

	> configure: WARNING: LRELEASE not found; bitcoin-qt frontend will not be built

	```bash
	$ sudo apt-get install --yes qttools5-dev-tools
	```

* gettext

	> configure: WARNING: xgettext is required to update qt translations

	```bash
	$ sudo apt-get install --yes gettext
	```

* SQLite

	> test_framework.authproxy.JSONRPCException: Compiled without sqlite support (required for descriptor wallets)

	> error message: 'Compiled without sqlite support (required for descriptor wallets)'.

	```bash
	$ sudo apt-get install --yes libsqlite3-dev
	```


## Task 2: Run the unit and functional tests

> Run the unit and functional tests. Instructions on how to do that can be found here: (https://github.com/bitcoin/bitcoin/blob/master/test/README.md).

```bash
$ sudo apt-get install --yes python3-zmq
$ time test/functional/test_runner.py --extended 2>&1 | tee test_runner.py.log
real    62m53.282s
user    86m31.072s
sys     8m5.844s
```


### Copying relevant output files
```bash
$ docker commit -m 'Task 2 solved.' $containerIdOrName bpd:task2
$ docker cp $containerIdOrName:/tmp/bitcoin/test_runner.py.log .
```


## Task 3: Mine a block and send it to another node

> Look at example_test.py in the functional test directory and try getting node 1 to mine another block, send it to node 2, and check that node 2 received it. In your response to this email, please include a link to a gist or code snippet that you used to complete this step.

```bash
# create backup
$ cp test/functional/example_test.py{,.bak}
# edit example
$ vi test/functional/example_test.py
```
```python
    def run_test(self):
        """Main test logic"""
        self.log.info("Chaincode Labs Seminar - Exercises for Bitcoin Protocol Development")

        peer_messaging = self.nodes[0].add_p2p_connection(BaseNode())

        blocks = [int(self.generate(self.nodes[0], sync_fun=lambda: self.sync_all(self.nodes[0:2]), nblocks=1)[0], 16)]

        self.log.info("Mine block with node 1 ...")
        self.tip = int(self.nodes[1].getbestblockhash(), 16)
        self.block_time = self.nodes[1].getblock(self.nodes[1].getbestblockhash())['time'] + 1
        height = self.nodes[1].getblockcount()
        block = create_block(self.tip, create_coinbase(height + 1), self.block_time)
        block.solve()
        block_message = msg_block(block)
        peer_messaging.send_message(block_message)
        self.tip = block.sha256
        blocks.append(self.tip)
        self.block_time += 1
        height += 1

        self.log.debug('node 1: ' + self.nodes[1].getbestblockhash())
        self.log.debug('node 2: ' + self.nodes[2].getbestblockhash())

        self.log.info("... send it to node 2 ...")
        self.connect_nodes(1, 2)
        self.sync_all()
        self.nodes[1].disconnect_p2ps()

        self.log.info("... and check that node 2 received it ...")
        self.log.debug('node 1: ' + self.nodes[1].getbestblockhash())
        self.log.debug('node 2: ' + self.nodes[2].getbestblockhash())
        assert_equal(
            self.nodes[1].getbestblockhash(),
            self.nodes[2].getbestblockhash(),
        )
```
```bash
$ test/functional/test_runner.py example_test.py 2>&1 | tee example_test.py.log
```


### Copying relevant output files
```bash
$ docker commit -m 'Task 3 solved.' $containerIdOrName bpd:task3
$ docker cp $containerIdOrName:/tmp/bitcoin/test/functional/example_test.py .
$ docker cp $containerIdOrName:/tmp/bitcoin/example_test.py.log .
```