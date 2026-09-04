// Command crap_funcs reports one JSON line per Go function: the file, the
// name, the first and the last line, and the cyclomatic complexity.
//
// It reads the file paths from standard input, one per line, because
// "go run" would take .go arguments as further files to compile.
//
//	printf 'a.go\nb.go\n' | go run crap_funcs.go
//
// A function literal keeps no record of its own. Its branches raise the
// complexity of the function around it, as its statements raise that
// function's coverage.
package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"os"
)

type record struct {
	File  string `json:"file"`
	Name  string `json:"name"`
	Start int    `json:"start"`
	End   int    `json:"end"`
	CC    int    `json:"cc"`
}

// complexity counts the decisions of a function: every branch adds one
// path to the single path a straight-line function has.
func complexity(fn *ast.FuncDecl) int {
	cc := 1
	ast.Inspect(fn, func(n ast.Node) bool {
		switch t := n.(type) {
		case *ast.IfStmt, *ast.ForStmt, *ast.RangeStmt:
			cc++
		case *ast.CaseClause:
			if len(t.List) > 0 { // "default" adds no decision
				cc++
			}
		case *ast.CommClause:
			if t.Comm != nil {
				cc++
			}
		case *ast.BinaryExpr:
			if t.Op == token.LAND || t.Op == token.LOR {
				cc++
			}
		}
		return true
	})
	return cc
}

func name(pkg string, fn *ast.FuncDecl) string {
	if fn.Recv == nil || len(fn.Recv.List) == 0 {
		return pkg + "." + fn.Name.Name
	}
	var receiver string
	switch t := fn.Recv.List[0].Type.(type) {
	case *ast.StarExpr:
		receiver = fmt.Sprintf("*%s", t.X)
	default:
		receiver = fmt.Sprintf("%s", t)
	}
	return fmt.Sprintf("%s.(%s).%s", pkg, receiver, fn.Name.Name)
}

func main() {
	fset := token.NewFileSet()
	out := json.NewEncoder(os.Stdout)
	in := bufio.NewScanner(os.Stdin)
	for in.Scan() {
		path := in.Text()
		if path == "" {
			continue
		}
		file, err := parser.ParseFile(fset, path, nil, 0)
		if err != nil {
			fmt.Fprintf(os.Stderr, "crap_funcs: %v\n", err)
			os.Exit(1)
		}
		for _, decl := range file.Decls {
			fn, ok := decl.(*ast.FuncDecl)
			if !ok || fn.Body == nil {
				continue
			}
			err := out.Encode(record{
				File:  path,
				Name:  name(file.Name.Name, fn),
				Start: fset.Position(fn.Pos()).Line,
				End:   fset.Position(fn.End()).Line,
				CC:    complexity(fn),
			})
			if err != nil {
				fmt.Fprintf(os.Stderr, "crap_funcs: %v\n", err)
				os.Exit(1)
			}
		}
	}
}
