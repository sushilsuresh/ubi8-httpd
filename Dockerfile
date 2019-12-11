FROM registry.access.redhat.com/ubi8/ubi:latest
RUN yum install --disablerepo=* --enablerepo=ubi-8-appstream --enablerepo=ubi-8-baseos httpd mod_ssl openssl -y && rm -rf /var/cache/yum
RUN echo "The HTTP Server is Running" > /var/www/html/index.html
RUN mkdir -p /var/www/ssl
RUN echo "The HTTPS Server is Running" > /var/www/ssl/index.html
COPY ssl.conf /etc/httpd/conf.d/
COPY www.example.com.crt /etc/pki/tls/certs/www.example.com.crt
COPY www.example.com.key /etc/pki/tls/private/www.example.com.key
COPY www.example.com.csr /etc/pki/tls/private/www.example.com.csr
EXPOSE 80 443
# Start the service
CMD ["-D", "FOREGROUND"]
ENTRYPOINT ["/usr/sbin/httpd"]
