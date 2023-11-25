FROM quay.io/projectquay/golang:1.20 as builder

WORKDIR /go/src/app
COPY . .
RUN go get
RUN make build

FROM scratch
WORKDIR /
COPY --from=builder /go/src/app/kbot .
COPY --from=alpine:latest /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
ENTRYPOINT ["./kbot"]


FROM quay.io/projectquay/golang:1.20 as builder

ARG TARGETOS
ARG TARGETARCH

WORKDIR /go/src/app
COPY . .
RUN make ${TARGETOS} ${TARGETARCH}

FROM scratch
WORKDIR /
COPY --from=builder /go/src/app/out/kubot* .
COPY --from=alpine:latest /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
ENTRYPOINT [ "./kubot" ]
CMD [ "start" ]