FROM nginx:alpine

ENV OPENVPN /etc/openvpn
ENV EASYRSA /usr/share/easy-rsa
ENV EASYRSA_PKI $OPENVPN/pki
ENV EASYRSA_VARS_FILE $OPENVPN/vars
ENV EASYRSA_CRL_DAYS 3650

RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories && \
    apk add --no-cache --update supervisor openssh openvpn iptables bash easy-rsa openvpn-auth-pam google-authenticator pamtester && \
    ln -s /usr/share/easy-rsa/easyrsa /usr/local/bin && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/* /var/cache/distfiles/* && \
    ssh-keygen -A -N '' && \
    sed -i 's/PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    echo "root:`date +%s`" | chpasswd 2>/dev/null && \
    ssh-keygen -q -N '' -f /root/.ssh/id_rsa && \
    cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys && \
    chmod 600 /root/.ssh/* && \
    mkdir -p \
    /etc/supervisor.d \
    /etc/openvpn \
    /var/log/openvpn \
    /var/log/nginx \
    /var/log/sshd \
    /var/log/supervisor \
    /var/tmp/nginx/client_body \
    /run/nginx && \
    rm -rf /var/log/nginx/* && \
	{ \
		echo "[program:nginx]"; \
		echo 'command=/usr/sbin/nginx -g "daemon off;"'; \
		echo "autostart=true"; \
		echo "autorestart=true"; \
		echo "startretries=5"; \
        echo "startsecs=0"; \
		echo "numprocs=1"; \
        echo "process_name=%(program_name)s_%(process_num)02d"; \
        echo "stderr_logfile=/var/log/%(program_name)s/stderr.log"; \
        echo "stderr_logfile_maxbytes=10MB"; \
        echo "stderr_logfile_backups=7"; \
        echo "stdout_logfile=/var/log/%(program_name)s/stdout.log"; \
        echo "stdout_logfile_maxbytes=10MB"; \
        echo "stdout_logfile_backups=7"; \
	} > /etc/supervisor.d/nginx.ini && \
	{ \
		echo "[program:openvpn]"; \
		echo 'command=/usr/local/bin/start-openvpn'; \
		echo "autostart=true"; \
		echo "autorestart=true"; \
		echo "startretries=5"; \
		echo "numprocs=1"; \
        echo "process_name=%(program_name)s_%(process_num)02d"; \
        echo "stderr_logfile=/var/log/%(program_name)s/error.log"; \
        echo "stderr_logfile_maxbytes=10MB"; \
        echo "stderr_logfile_backups=7"; \
        echo "stdout_logfile=/var/log/%(program_name)s/access.log"; \
        echo "stdout_logfile_maxbytes=10MB"; \
        echo "stdout_logfile_backups=7"; \
	} > /etc/supervisor.d/openvpn.ini && \
	{ \
        echo "[program:sshd]"; \
        echo 'command=/usr/sbin/sshd -D -e'; \
        echo "autostart=true"; \
        echo "autorestart=true"; \
        echo "startretries=5"; \
        echo "numprocs=1"; \
        echo "process_name=%(program_name)s_%(process_num)02d"; \
        echo "stderr_logfile=/var/log/%(program_name)s/error.log"; \
        echo "stderr_logfile_maxbytes=10MB"; \
        echo "stderr_logfile_backups=7"; \
        echo "stdout_logfile=/var/log/%(program_name)s/access.log"; \
        echo "stdout_logfile_maxbytes=10MB"; \
        echo "stdout_logfile_backups=7"; \
    } > /etc/supervisor.d/openssh.ini

ADD ./docker-openvpn/bin /usr/local/bin
ADD ./docker-openvpn/otp/openvpn /etc/pam.d/
ADD ./docker-compose.yml ./init.sh /
ADD ./bin/* /usr/local/bin/

RUN chmod a+x /usr/local/bin/*

CMD [ "supervisord", "-n", "-c", "/etc/supervisord.conf" ]
