from setuptools import setup, find_packages

setup(
    name='fj_farmjennycellular',
    version='0.4.7',
    author='Rob Crouthamel',
    author_email='rob@farmjenny.com',
    description='farm jenny cellular python libraries',
    license='MIT',
    url='https://github.com/farmjenny/Farm_Jenny_Installer',
	install_requires  = ['RPi.GPIO', 'pyserial'],
    packages=find_packages()
)
