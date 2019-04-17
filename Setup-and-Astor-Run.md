## VM Setup and Astor run

To run Astor for our final setup follow this guideline.



### VM Creation:

- **6vCPUs** - *because Astor does only require a fraction of the available resources*
- **39GB Memory** - *this should be enough*
- **Debian 9 Stretch**



### Initialization of the System:

Just install all the necessary tools.

```console
sudo apt-get update
sudo apt-get install git vim software-properties-common maven debian-archive-keyring openjdk-8-jdk
```



### Install JAVA 7:

Install both JRE/JDK 8 and 7, because Astor needs JRE 8 and defect4j needs 7 (find the source for this again).

```console
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 8B48AD6246925553
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 7638D0442B90D010
sudo add-apt-repository 'deb http://httpredir.debian.org/debian experimental main'
sudo add-apt-repository 'deb http://httpredir.debian.org/debian sid main'
sudo apt-get update
sudo apt-get install openjdk-7-jdk
```



### Setup Astor:

Setup our fork version of Astor, with all the tests etc.

```console
git clone https://github.com/jan-gerling/astor.git
cd astor
git checkout reproduce
git pull
```



### Run Tests:

For convenience I wrote this bash script iterating over all folder in the given path (argument one) and the full path to the astor root folder (argument two), build the test case to fix, and then apply all three scopes and modes on them. ([bash script src](<https://github.com/jan-gerling/astor/blob/reproduce/astor_runner.sh>)) 

```console
chmod u+x astor_runner.sh
./astor_runner.sh ~/astor/defect4j_tests/ ~/astor/
```

### Results:
A summary of the results containing an execution summary and state can be found in results/summary-*date*.txt
Detailed output for each execution can be found in /results.

