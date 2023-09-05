from selenium import webdriver
from urllib.request import urlopen
from bs4 import BeautifulSoup
import pandas as pd
import numpy as np
import time
import sys

"""
使用PhantomJS作为web驱动
# Download and unzip PhantomJS at https://phantomjs.org/download.html
# Make sure Phantomjs bin is set into PATH
# 新版Selenium已經不支持PhantomJS了
# 如果一定要用PhantomJS,那要考慮卸載當前Selenium,降檔到3.141.0或者以下版本去用
# 如果只是為了無界面,也可以考慮用chorme,用無界面模式。
# driver = webdriver.PhantomJS()

使用Chrome作为web驱动
# Download the driver that matches your browser version at this address
# http://chromedriver.storage.googleapis.com/index.html
# And make sure chromedriver is set into PATH
# 也支持无界面模式
# opt = webdriver.ChromeOptions()
# opt.set_headless()
# driver = webdriver.Chrome(options=opt)
"""

def get_bk(bk_type='industry'):
    """
    bk_type: 东方财富板块类型, industry/concept/region
    对应可插入的数据表: east_bk_info
    """
    type_dict = {"industry": "行业板块", "concept": "概念板块", "region": "地区板块"}

    pageUrl = "http://quote.eastmoney.com/center/"
    # 其他可用url: https://data.eastmoney.com/bkzj/hy.html
    # 其他可用url: https://data.eastmoney.com/bkzj/gn.html

    opt = webdriver.ChromeOptions()
    opt.set_headless()
    driver = webdriver.Chrome(options=opt)

    driver.get(pageUrl)
    # necessary sleep waiting for page load
    time.sleep(2)
    html = driver.execute_script('return document.documentElement.outerHTML')
    bsObj = BeautifulSoup(html, 'html.parser')

    # find content by bk type
    if bk_type == "industry":
        content = bsObj.find("li", {"class": "sub-items menu-industry_board-wrapper"}).findAll("a")[1:]
    elif bk_type == "concept":
        content = bsObj.find("li", {"class": "sub-items menu-concept_board-wrapper"}).findAll("a")[1:]
    elif bk_type == "region":
        content = bsObj.find("li", {"class": "sub-items menu-region_board-wrapper"}).findAll("a")[1:]
    else :
        print("Unrecognized bk type:", bk_type)
        sys.exit()

    bk_list = []
    for i in content:
        code = i.attrs['href'].split(".")[-1]
        name = i.attrs['title']
        url = "http://data.eastmoney.com/bkzj/" + code + ".html"
        bk_info = dict(zip(['bk_code', 'bk_name', 'url'], [code, name, url]))
        bk_list.append(bk_info)

    df = pd.DataFrame(bk_list)
    df['bk_type'] = type_dict[bk_type]
    return df


def get_hangye() :
    '''
    等同于get_bk('industry')
    '''
    pageUrl = "http://stock.eastmoney.com/hangye.html"
    html = urlopen(pageUrl)
    bsObj = BeautifulSoup(html, 'html.parser')
    content = bsObj.find("div", {"class": "hot-hy-list"}).findAll("a")
    print(len(content), "hangye found.")
    html.close()

    hangye_list = []
    for i in content:
        code = i.attrs['href'].split('hy')[1].split('.')[0]
        if len(code)==3:
            code = "BK0"+code
        else : #4
            code = "BK"+code

        name = i.attrs['title']
        url = "http://data.eastmoney.com/bkzj/" + code + ".html"
        hangye_list.append({"bk_code":code, "bk_name":name, "url":url})

    df = pd.DataFrame(hangye_list)
    df['bk_type'] = '行业板块'
    return df

            
def get_bk_stock(bk_code):
    """
    bk_code: 东方财富板块代码, 例如BK0420

    如何实现动态网页爬虫，参考 https://blog.csdn.net/qwdpoiguw/article/details/79683832
    如何实现表格翻页，参考 https://blog.csdn.net/wendyw1999/article/details/107414953

    对应可插入的数据表: east_bk_stock
    """
    opt = webdriver.ChromeOptions()
    opt.set_headless()
    driver = webdriver.Chrome(options=opt)

    # Wait for the page to load before getting the content (FOR ACTIVE TABLE)
    url = "http://data.eastmoney.com/bkzj/" + bk_code + ".html"
    driver.get(url)
    time.sleep(2)

    # Get stock list for bk
    stock_list = []
    while(True) :
        # Extract HTML content
        html = driver.execute_script('return document.documentElement.outerHTML')

        # bs formatted and find your content
        bsObj = BeautifulSoup(html, 'html.parser')
        content = bsObj.find("div", {"id": "dataview"}).find("tbody").findAll("a")
        # get stock_code and stock_name
        for i in np.arange(int(len(content) / 5)) * 5:
            code = content[i].get_text()
            name = content[i + 1].get_text()
            stock_list.append([code, name])
        try:
            # Find next table page element
            # Sleep is essential, otherwise a mistake will occur
            next_page = driver.find_element_by_link_text("下一页")
            time.sleep(2)

            # If at last table page
            if next_page.get_attribute("class") == "nolink":
                break

            # Take your driver into next table page by click
            # Sleep is essential, otherwise a mistake will occur
            next_page.click()
            time.sleep(2)
            
        except Exception as e:
            # If table just has only one page
            print(e)
            break

    driver.quit()
    df = pd.DataFrame(stock_list, columns=['stock_code','stock_name'])
    df['bk_code'] = bk_code
    return df
