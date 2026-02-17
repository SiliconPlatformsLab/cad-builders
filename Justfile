charon:
    docker build . -f Charon.Dockerfile  --progress=plain -t sip-lab/charon:latest

xyce:
    docker build . -f Xyce.Dockerfile  --progress=plain -t sip-lab/xyce:latest
