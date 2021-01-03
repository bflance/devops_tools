#!/bin/bash

read -sp "Enter encryption password: " PASSWORD
echo ""
read -sp "Confirm encryption password: " PASSWORD_CONFIRM
echo ""

if [[ "$PASSWORD" != "$PASSWORD_CONFIRM" ]]; then
        echo "ERROR: Passwords do not match!"
        exit 1
fi

echo "Enter your AWS_ACCESS_KEY_ID:"
read AWS_ACCESS_KEY_ID

echo "Enter your AWS_SECRET_ACCESS_KEY:"
read AWS_SECRET_ACCESS_KEY

export PASSW=$PASSWORD
AWS_ACCESS_KEY_ID_ENC=$(echo "$AWS_ACCESS_KEY_ID" | openssl enc -e -aes-256-cbc -pbkdf2 -pass env:PASSW | openssl base64 -A)
AWS_SECRET_ACCESS_KEY_ENC=$(echo "$AWS_SECRET_ACCESS_KEY" | openssl enc -e -aes-256-cbc -pbkdf2 -pass env:PASSW | openssl base64 -A)
unset PASSW

cat > ./awscreds.sh <<EOF
#!/bin/bash
AWS_ACCESS_KEY_ID_ENC="$AWS_ACCESS_KEY_ID_ENC"
AWS_SECRET_ACCESS_KEY_ENC="$AWS_SECRET_ACCESS_KEY_ENC"
read -sp "Enter encryption password: " PASSWORD
export PASSW=\$PASSWORD
AWS_ACCESS_KEY_ID=\$(echo -n "\$AWS_ACCESS_KEY_ID_ENC" | openssl base64 -d -A | openssl enc -d -aes-256-cbc -pbkdf2 -pass env:PASSW)
AWS_SECRET_ACCESS_KEY=\$(echo -n "\$AWS_SECRET_ACCESS_KEY_ENC" | openssl base64 -d -A | openssl enc -d -aes-256-cbc -pbkdf2 -pass env:PASSW)
if [ \$? -ne 0 ]; then
        unset PASSW
        echo "ERROR: Password doesn't appear correct!"
        echo "Unsetting environment variables ..."
        unset AWS_ACCESS_KEY_ID
        unset AWS_SECRET_ACCESS_KEY
        return 1
fi
unset PASSW
echo ""
echo "Setting AWS ACCESS environment variables ..."
export AWS_ACCESS_KEY_ID=\$AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=\$AWS_SECRET_ACCESS_KEY
EOF

chmod +x ./awscreds.sh

echo "Run '. ./awscreds.sh' to decrypt and apply AWS keys to the current environment"

