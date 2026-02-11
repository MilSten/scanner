FROM golang:1.24-alpine AS nuclei-builder

RUN apk add --no-cache git build-base

RUN CGO_ENABLED=0 go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest

FROM eclipse-temurin:21-jdk-jammy

RUN apt-get update && apt-get install -y --no-install-recommends \
    nmap \
    perl \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt
RUN git clone https://github.com/sullo/nikto.git \
    && chmod +x /opt/nikto/program/nikto.pl \
    && ln -s /opt/nikto/program/nikto.pl /usr/local/bin/nikto

COPY --from=nuclei-builder /go/bin/nuclei /usr/local/bin/nuclei

RUN nuclei -update-templates

WORKDIR /app
COPY target/scanner-*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
