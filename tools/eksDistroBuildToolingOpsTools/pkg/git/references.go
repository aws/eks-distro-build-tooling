package git

import "fmt"

type ReferenceType interface {
	Prefix()          string
	Suffix()          string
	ReferenceString() string
}

type BranchRefType struct {}

func (b *BranchRefType) Prefix() string {
	return "refs"
}

func (b *BranchRefType) Suffix() string {
	return "branch"
}

func (b *BranchRefType) ReferenceString() string {
	return fmt.Sprintf("%s/%s", b.Prefix(), b.Suffix())
}

type TagRefType struct {}

func (t *TagRefType) Prefix() string {
	return "refs"
}

func (t *TagRefType) Suffix() string {
	return "tag"
}

func (t *TagRefType) ReferenceString() string {
	return fmt.Sprintf("%s/%s", t.Prefix(), t.Suffix())
}