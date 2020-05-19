from setuptools import setup, find_packages

setup(
    name='fj_farmjennycellular',
    version='0.2.0',
    author='Rob Crouthamel',
    author_email='rob@farmjenny.com',
    description='farm jenny cellular python libraries',
    license='MIT',
    url='https://github.com/farmjenny/Farm_Jenny_Installer',
    dependency_links  = ['https://github.com/adafruit/Adafruit_Python_GPIO/tarball/master#egg=Adafruit-GPIO-0.9.3'],
	install_requires  = ['Adafruit-GPIO>=0.9.3', 'pyserial'],
    packages=find_packages()
)
