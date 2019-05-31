FROM arm32v7/gcc as builder


RUN curl -s https://api.github.com/repos/jedisct1/pure-ftpd/releases/latest | grep "browser_download_url.*tar.gz" | head -n 1 | cut -d : -f 2,3 | tr -d \" | wget -qi - \
    && tar -xvzf pure-ftpd*.tar.gz \
    && cd pure-ftpd-* \
    && ./configure --with-tls --with-puredb && make && make install

#RUN wget https://github.com/jedisct1/pure-ftpd/releases/download/1.0.49/pure-ftpd-1.0.49.tar.gz

#FROM scratch
#COPY --from=builder /usr/local/sbin/pure-ftpd /usr/sbin/
#COPY --from=builder /etc/pure-ftpd.conf /etc/

RUN cp /usr/local/sbin/pure-ftpd /usr/sbin/

# setup ftpgroup and ftpuser
RUN mkdir -p /home/ftpusers && mkdir -p /etc/pure-ftpd/passwd/ && groupadd ftpgroup &&\
    useradd -g ftpgroup -d /home/ftpusers  ftpuser

# configure rsyslog logging
RUN echo "" >> /etc/rsyslog.conf && \
    echo "#PureFTP Custom Logging" >> /etc/rsyslog.conf && \
    echo "ftp.* /var/log/pure-ftpd/pureftpd.log" >> /etc/rsyslog.conf && \
    echo "Updated /etc/rsyslog.conf with /var/log/pure-ftpd/pureftpd.log"

USER root
# setup run/init file
COPY run.sh /run.sh
COPY run-1.sh /run-1.sh
RUN chmod u+x /run.sh /run-1.sh
# default publichost, you'll need to set this for passive support
ENV PUBLICHOST localhost

CMD /run-1.sh  -l puredb:/etc/pure-ftpd/pureftpd.pdb -E -j -R -P $PUBLICHOST && /run.sh -l puredb:/etc/pure-ftpd/pureftpd.pdb -E -j -R -P $PUBLICHOST
