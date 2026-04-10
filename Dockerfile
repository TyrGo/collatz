# TODO: pin to a specific version tag (e.g. dyalog/dyalog:19.0) for reproducible builds.
FROM dyalog/dyalog
COPY *.dyalog *.dyapp index.html /app/
EXPOSE 8080
