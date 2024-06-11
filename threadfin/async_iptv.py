import aiohttp
import asyncio
import requests
import argparse
import time
import re

def download_m3u(url):
    response = requests.get(url)
    response.raise_for_status()
    return response.text

def is_english(s):
    return re.match(r'^[\x00-\x7F]+$', s) is not None

def parse_m3u(content, check_non_english):
    lines = content.splitlines()
    urls = []
    metadata = None
    for line in lines:
        line = line.strip()
        if line.startswith('#EXTM3U'):
            continue
        if line.startswith('#EXTINF'):
            metadata = line
        elif line and metadata:
            title_match = re.search(r',(.+)$', metadata)
            if title_match:
                title = title_match.group(1)
                if check_non_english and not is_english(title):
                    metadata = None
                    continue
            urls.append((metadata, line))
            metadata = None
    return urls

async def check_channel(url, session, timeout):
    try:
        async with session.head(url, timeout=timeout) as response:
            if response.status == 200:
                return url
    except:
        pass
    return None

async def main(m3u_url, timeout, check_non_english):
    m3u_content = download_m3u(m3u_url)
    channels = parse_m3u(m3u_content, check_non_english)

    async with aiohttp.ClientSession() as session:
        tasks = [check_channel(url, session, timeout) for metadata, url in channels]
        results = await asyncio.gather(*tasks)

    active_channels = [(metadata, url) for (metadata, url), result in zip(channels, results) if result]
    return active_channels

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='IPTV Scanner')
    parser.add_argument('m3u_url', type=str, help='URL to the .m3u file')
    parser.add_argument('--timeout', '-t', type=int, default=1, help='Timeout for checking channels in seconds')
    parser.add_argument('--check-non-english', '-c', action='store_true', help='Ignore titles with non-English characters')
    parser.add_argument('--silent', '-s', action='store_true', help='Suppress stats of active channels and execution time')
    args = parser.parse_args()

    start_time = time.time()
    active_channels = asyncio.run(main(args.m3u_url, args.timeout, args.check_non_english))
    end_time = time.time()

    print(f"Active channels ({len(active_channels)}):")
    for metadata, channel in active_channels:
        print(f"{metadata}\n{channel}")
    
    if not args.silent:
        print(f"Execution time: {end_time - start_time} seconds")
