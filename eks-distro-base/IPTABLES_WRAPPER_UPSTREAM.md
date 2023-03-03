This has been copied in its entirety from https://github.com/kubernetes-sigs/iptables-wrappers/pull/6 which was contributed by
EKS-Anywhere engineer, https://github.com/g-gaston.  Once merged upstream this will be changed to pull from the upstream repo.
Hardcoding for now to avoid the branch going away or changing and breaking future builds.

Manual steps to pull:
- git clone https://github.com/g-gaston/iptables-wrappers.git iptables-wrapper-upstream && \
    rm -rf iptables-wrappers && mkdir iptables-wrappers && \
    git -C iptables-wrapper-upstream checkout go-wrapper && \
    cp -rf iptables-wrapper-upstream/{internal,go.mod,LICENSE,main.go,Makefile,test} iptables-wrappers && \
    rm -rf iptables-wrapper-upstream