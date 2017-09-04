#!/usr/bin/env python
# -*- coding: utf-8 -*-

################################################################################
#
# caos-tsdb - CAOS Time-Series DB
#
# Copyright © 2017 INFN - Istituto Nazionale di Fisica Nucleare (Italy)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#
# Author: Fabrizio Chiarello <fabrizio.chiarello@pd.infn.it>
#
################################################################################

import logging
import sys

import requests


logger = logging.getLogger()
logger.setLevel(logging.DEBUG)
logger.addHandler(logging.StreamHandler())


class ConnectionError(Exception):
    pass


class AuthError(Exception):
    pass


_caos_tsdb_api_url = None
_token = None


class JWTAuth(requests.auth.AuthBase):
    def __call__(self, r):
        r.headers['Authorization'] = "Bearer %s" % _token
        return r


__jwt_auth = JWTAuth()


def die(msg):
    logger.error("DIE: {msg}".format(msg=msg))
    sys.exit(1)


def _request(rest_type, api, data=None, params=None):
    fun = getattr(requests, rest_type)
    url = "%s/%s" % (_caos_tsdb_api_url, api)

    logger.debug("REST request: {type} {url} params={params} json={json}"
                 .format(type=rest_type, url=url, params=params, json=data))

    r = None
    try:
        r = fun(url, json=data, params=params, auth=__jwt_auth, verify=False)
    except requests.exceptions.ConnectionError as e:
        raise ConnectionError(e)

    r.raise_for_status()
    try:
        json = r.json()
    except:
        die("REST content: {content}".format(content=r.content))

    logger.debug("REST status: %s json=%s", r.status_code, json)

    if r.ok and 'data' in json:
        return json['data']
    return r.ok


def get(api, params=None):
    return _request('get', api, params=params)


def post(api, data, request='post'):
    return _request(request, api, data)


def check_status():
    status = get('v1/status')
    assert 'status' in status
    assert status['status'] == 'online'


def check_auth():
    status = get('v1/status')
    assert 'auth' in status
    assert status['auth'] == 'no'

    def get_token(username, password):
        params = {
            'username': username,
            'password': password
        }

        data = post('v1/token', data=params)
        if not data or 'token' not in data:
            raise AuthError("No token returned")

        token = data['token']
        return token

    token = get_token(username="admin", password="ADMIN_PASS")
    logger.info("Got new token: {token}".format(token=token))

    global _token
    _token = token

    status = get('v1/status')
    assert 'auth' in status
    assert status['auth'] == 'yes'


def main(args):
    if len(args) != 2:
        die("Endpoint not given.")

    global _caos_tsdb_api_url
    _caos_tsdb_api_url = args[1]

    logger.info("Checking status")
    check_status()

    logger.info("Checking auth")
    check_auth()


if __name__ == "__main__":
    main(sys.argv)
    sys.exit(0)
