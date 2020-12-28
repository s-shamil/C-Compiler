/*int f(int n){
  int x;
  if(n==0){
     x = 1;
  }
  else {
     x = n * f(n-1);
  }
  return x;
}
int main(){
    int a;
    a = f(5);
    println(a);
}
*/

int main(){
    int a,b,i;
    b=0;
    for(i=0;i<4;i++){
        a=3;
        while(a--){
            b++;
        }
    }
    println(a);
    println(b);
}
