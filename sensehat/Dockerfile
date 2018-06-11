FROM resin/rpi-raspbian:stretch

RUN [ "cross-build-start" ]

RUN apt-get update && apt-get install sense-hat

COPY app.py /opt/app.py
ENV PORT 8080
EXPOSE 8080
WORKDIR /opt
ENTRYPOINT ["python"]
CMD ["app.py"]
