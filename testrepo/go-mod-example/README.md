# go-mod-example
Go Modules Example

* `go mod init github.com/skyrocknroll/go-mod-example`
* You can dependency using `go get` which modules aware if the package is module enabled. https://tip.golang.org/cmd/go/#hdr-Module_aware_go_get
* You can also explicitly add dependency in go.mod require block `github.com/sirupsen/logrus v1.2.0`
* Write the code with dependencies
* go build server.go will populate go.mod go.sum
