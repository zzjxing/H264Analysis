set -e

# required
arch=$(arch)
gover="1.18.3"

if [[ $arch == "x86_64" ]]; then
    tag="amd64"
elif [[ $arch == "aarch64" ]]; then
    tag="arm64"
else
    echo "unknown system arch $arch"
    exit 1
fi

gopkg=/opt/go.tar.gz

# download go
rm -rf $gopkg

url=https://golang.google.cn/dl/go${gover}.linux-${tag}.tar.gz
echo "download $url"
wget -q --show-progress -O  $gopkg  $url

# prepare golang
rm -rf /usr/bin/go /usr/local/go /opt/go
tar xzf $gopkg -C /opt/
ln -s /opt/go/bin/go /usr/bin/go
ln -s /opt/go/bin/go /usr/local/go
rm -rf $gopkg

currVer=$(go version | awk '{print $3}')
if [[ $currVer != "go${gover}" ]]; then
    echo "go install failed, go now is located: $(which go), version: $(go version)"
    exit 1
fi

# prepare bin
#cp -f $bin /usr/local/bin

gopath=/opt/gopath
if [[ ! -z ${CUSTOM_GOPATH} ]]; then
    gopath=${CUSTOM_GOPATH}/gopath
fi

# prepare GOPATH
rm -rf $gopath && mkdir -p $gopath

export PATH=/opt/go/bin:$PATH
#go env -w GOPROXY="https://goproxy.cn,direct"
#go env -w GOPROXY="https://mirrors.aliyun.com/goproxy/,direct"
go env -w GOPROXY=https://goproxy.cn,direct
go env -w GO111MODULE="on"
go env -w GOPATH=$gopath
go env -w GOBIN=$gopath/bin
#go env -w GOSUMDB="gosum.io+ce6e7565+AY5qEHUk/qmHc5btzW45JVoENfazw8LielDsaI+lEbq6"
go env -w GOSUMDB="off"

#go get -u golang.org/x/lint/golint
#go get github.com/golangci/golangci-lint/cmd/golangci-lint@v1.31.0
#wget q --show-progress -O  https://github.com/golangci/golangci-lint/releases/download/v1.46.2/golangci-lint-1.46.2-linux-amd64.tar.gz

#tar -zxvf golangci-lint-1.46.2-linux-amd64.tar.gz
#mv golangci-lint-1.46.2-linux-amd64/golangci-lint $GOPATH/bin/

go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.46.2

echo "=================================================="
echo "Go develop environment prepared"
echo "=================================================="
