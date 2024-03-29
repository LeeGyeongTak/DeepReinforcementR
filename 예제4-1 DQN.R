
## relu 함수
relu<-function(x){
  ifelse(x>0,x,0)
}


##network feedforward

nn.ff<-function (nn, batch_x) 
  
{
  m <- nrow(batch_x)
  
  if (nn$visible_dropout > 0) {
    nn$dropout_mask[[1]] <- dropout.mask(ncol(batch_x), nn$visible_dropout)
    batch_x <- t(t(batch_x) * nn$dropout_mask[[1]])
  }
  
  nn$post[[1]] <- batch_x
  
  for (i in 2:(length(nn$size) - 1)) {
    nn$pre[[i]] <- t(nn$W[[i - 1]] %*% t(nn$post[[(i - 1)]]) + 
                       nn$B[[i - 1]])
    
    if (nn$activationfun == "sigm") {
      nn$post[[i]] <- sigm(nn$pre[[i]])
    }
    
    else if (nn$activationfun == "tanh") {
      nn$post[[i]] <- tanh(nn$pre[[i]])
    }
    else if (nn$activationfun == "relu") {
      nn$post[[i]] <- relu(nn$pre[[i]])
    }
    else if (nn$activationfun == "linear") {
      nn$post[[i]] <- (nn$pre[[i]])
    }
    else {
      stop("unsupport activation function!")
          }
    
    if (nn$hidden_dropout > 0) {
      nn$dropout_mask[[i]] <- dropout.mask(ncol(nn$post[[i]]), 
                                           nn$hidden_dropout)
      nn$post[[i]] <- t(t(nn$post[[i]]) * nn$dropout_mask[[i]])
       }
    }
  
  
  i <- length(nn$size)
  nn$pre[[i]] <- t(nn$W[[i - 1]] %*% t(nn$post[[(i - 1)]]) + 
                     nn$B[[i - 1]])
  
  
  if (nn$output == "sigm") {
    nn$post[[i]] <- sigm(nn$pre[[i]])
    
  } else if (nn$output == "linear") {
    nn$post[[i]] <-  nn$pre[[i]] 
    
  } else if (nn$output == "softmax") {
    
    nn$post[[i]] <- exp(nn$pre[[i]])
    nn$post[[i]] <- nn$post[[i]]/rowSums(nn$post[[i]])
    nn$post[[i]][is.na(nn$post[[i]] )]<-1
    
  }
  nn
  
}




## network back propagation
nn.bp<-function (nn) 
{
  n <- length(nn$size)
  d <- list()
  if (nn$output == "sigm") {
    d[[n]] <- -nn$e * (nn$post[[n]] * (1 - nn$post[[n]]))

  }
  else if (nn$output == "linear" || nn$output == "softmax") {
    d[[n]] <- -nn$e
  }
  
  for (i in (n - 1):2) {
    if (nn$activationfun == "sigm") {
              d_act <- nn$post[[i]] * (1 - nn$post[[i]])
    }
    else if (nn$activationfun == "tanh") {
        d_act <- 1.7159 * 2/3 * (1 - 1/(1.7159)^2 * nn$post[[i]]^2)
    }
    else if (nn$activationfun == "relu") {
        d_act <-  ifelse(nn$post[[i]]>=0,1,0)
    }
      d[[i]] <- (d[[i + 1]] %*% nn$W[[i]]) * d_act
   if (nn$hidden_dropout > 0) {
        d[[i]] <- t(t(d[[i]]) * nn$dropout_mask[[i]])
    }
  }
  
  for (i in 1:(n - 1)) {
    dw <- t(d[[i + 1]]) %*% nn$post[[i]]/nrow(d[[i + 1]])
    dw <- dw * nn$learningrate
    
    if (nn$momentum > 0) {
      nn$vW[[i]] <- nn$momentum * nn$vW[[i]] + dw
      dw <- nn$vW[[i]]
    }
    
    nn$W[[i]] <- nn$W[[i]] - dw
    db <- colMeans(d[[i + 1]])
    db <- db * nn$learningrate
    
    if (nn$momentum > 0) {
      nn$vB[[i]] <- nn$momentum * nn$vB[[i]] + db
      db <- nn$vB[[i]]
    }
    
    nn$B[[i]] <- nn$B[[i]] - db
    
  }
  
  nn
  
}


sigm<-function (x) {
  1/(1 + exp(-x))
}



######################
coord<-function(state){
  re_index<-which(state==1)
  xx<-ceiling(re_index/ 10) ## 행
  yy<-re_index %% 10  ## 열
  yy<-ifelse(yy ==0,10,yy)
  c(xx,yy)
}


stm<-matrix(1:100,ncol=10,nrow=10,byrow=T)
action<-c("left","right","down","up")

state_size <-ncol(stm)*nrow(stm)

## 10 x 10  frozen lake problem
# S : start, F : Frozen, H : Hole, G : Goal 
# SFFFF|FFFFF
# FHFFF|FFFFF
# FFFFF|FFFFF
# FFFFF|FFFFF
# FHFHH|FFFFF
# FFFFF|FFFFF
# FFFFF|FFHFF
# FHFFF|FFFFH
# FFFFF|FFFFF
# FFFFF|FFFFG
move<-function(x,action){
  
  if(action == "left"){
    if(x[2]-1<1){
      x
    }else{
      x[2]<-x[2]-1
      x
    }
  }
  if(action == "right"){
    if(x[2]+1>ncol(stm)){
      x
    }else{
      x[2]<-x[2]+1
      x
    }
  }
  if(action == "up"){
    if(x[1]-1<1){
      x
    }else{
      x[1]<-x[1]-1
      x
    }
  }
  if(action == "down"){
    if(x[1]+1>nrow(stm)){
      x
    }else{
      x[1]<-x[1]+1
      x
    }
  }
  x
}


next_where<-function(index){ 
  zero<-rep(0,100)
  zero[index]<-1
  zero
}





return_reward<-function(next_state,current_state){
re_index<-which(next_state==1)

if(re_index==100){
  reward<- 5# episode end
  done<-T
}
else if(sum(c(12,19,29,39,42,44,45,68,72,80) %in% re_index) ==1){
  reward<- -2
  done<-F
}else{
  reward <- -1
  done<-F
}
if(re_index==which(current_state==1)){
  reward<-reward*2
}
if(step==500){
  done<-T
}
c(reward,done)

}



########어려운 Environment 버젼
return_reward<-function(next_state,current_state){
  re_index<-which(next_state==1)
  
  if(re_index==100){
    reward<- 5# episode end
    done<-T
  }
  else if(sum(c(12:16,19,22,32,42,53,81:86,29,39,42,44,45,68,72,80) %in% re_index) ==1){
    reward<- -2
    done<-F
  }else{
    reward <- -1
    done<-F
  }
  if(re_index==which(current_state==1)){
    reward<-reward*2
  }
  
  c(reward,done)
  
}

### initialize neural network



{
  
  
  input_dim<-state_size
  hidden<-c(30)
  output_dim<-4
  size <- c(input_dim, hidden, output_dim)
  activationfun<-"relu"
  output<-"linear"
  
  momentum<-0
  learningrate_scale<-1
  hidden_dropout = 0
  visible_dropout = 0
  learningrate<-0.01
  
  
  vW <- list()
  vB <- list()
  W <- list()
  B <- list()
  
  
  
  for (i in 2:length(size)) {
    W[[i - 1]] <- matrix(runif(size[i] * size[i - 1], 
                               min = -0.1, max = 0.1), c(size[i], size[i - 1]))
    B[[i - 1]] <- runif(size[i], min = -0.1, max = 0.1)
    vW[[i - 1]] <- matrix(rep(0, size[i] * size[i - 1]), 
                          c(size[i], size[i - 1]))
    vB[[i - 1]] <- rep(0, size[i])
  }
  qn1<- list(input_dim = input_dim, output_dim = output_dim, 
             hidden = hidden, size = size, activationfun = activationfun, 
             learningrate = learningrate, momentum = momentum, learningrate_scale = learningrate_scale, 
             hidden_dropout = hidden_dropout, visible_dropout = visible_dropout, 
             output = output, W = W, vW = vW, B = B, vB = vB)
  
  
  #### target network
  target_qn<-qn1
  
  
}



epoch<-50
mini_batch<-20
init_data<-c(1,rep(0,state_size-1))
dis_f<-0.99
reward_list<-c()
final_action_list<-list()
step_list<-c()
q_table<-list()
replay_buffer<-list()

r<-1
bi<-1



for(i in 1:10000){
  
  
  
  total_r<-0 ## total reward
  episode_done<-0 
  
  qn1<-nn.ff(qn1,t(init_data))
  step<-1
  action_list<-NULL
  st<-c(1,1)
  
  
  while(episode_done==0){
    
    if(step >1){
      qn1<-nn.ff(qn1,t(next_state))
      action_index<-which.max(qn1$post[[length(size)]])
      current_state<-next_state
    }else{
      current_state<-init_data
      action_index<-which.max(qn1$post[[length(size)]])
      
    }
    
    th<-1/(i/50+10)
    if(runif(1) < th){ ## e-greedy search
      next_action<-  action[sample(1:4,1)]
      
    }else{
      next_action<-action[action_index]
    }
    
    
    ####### if episode smaller than 10, just choose action randomly
    if(i < 10){
      next_action<-  action[sample(1:4,1)]
    }
    
    action_list<-c(action_list,next_action)
    st<-move(st,next_action)
    state_index<-stm[st[1],st[2]]
    
    
    next_state<-next_where(state_index)
    re_ep<-return_reward(next_state,current_state) ## get a reward and Whether the episode ends for action(next state)
    
    total_r<-total_r+re_ep[1]
    episode_done<-re_ep[2]
    step<-step+1
    
    
    
    #########       
    #### store current state, action, reward, done, next_state at replay_buffer
    
    replay_buffer[[bi]]<-  c(which(current_state==1),next_action,re_ep,state_index)
    bi<-bi+1
    if(bi == 100000){
      bi <- 1
    }
    
    
    if(step == 500 |episode_done==1){
      cat("\n",i," epsode-",step) 
      step_list<-c(step_list,step)
      final_action_list[[i]]<-action_list
      reward_list<-c(reward_list,total_r)
      
      cat("\n final location")
      print(coord(next_state))
      ts.plot(reward_list,main=paste0((reward_list)[length(reward_list)],"-",step,"-",min(step_list)))
      break;
    }
   
   
    
  }
  
  

    if(i %% 5==0){
      
      
      ### sampling from replay_buffer
      for(u in 1:epoch){
        
        sam<-sample(1:length(replay_buffer),mini_batch)
        sam_1<-replay_buffer[sam]

        
        x_stack<-NULL
        y_stack<-NULL

        for(q in 1:length(sam_1)){
          re<-rep(0,state_size)
          re[as.numeric(sam_1[[q]][1])]<-1
          x_stack<- rbind(x_stack,re) ##x stack
          qvalue<-nn.ff(qn1,t(re))$post[[length(qn1$size)]]
          
          ######### state, action, reward, done, next_state
          ## sam_1[[q]][1] current_state
          ## sam_1[[q]][2] action
          ## sam_1[[q]][3] reward
          ## sam_1[[q]][4] episode done
          ## sam_1[[q]][5] next_state
          
          if( sam_1[[q]][4]==1){
            
            qvalue[action==sam_1[[q]][2]]<-as.numeric(sam_1[[q]][3])
            y_stack<-rbind(y_stack,qvalue) ## y stack
            
          }else{
            
            re2<-rep(0,state_size)
            re2[as.numeric(sam_1[[q]][5])]<-1
            
            target_qn<-nn.ff(target_qn,t(re2)) ## feed forward using target netwrok
            true_y<-max(target_qn$post[[length(target_qn$size)]]) 
            qvalue[action==sam_1[[q]][2]]<-   as.numeric(sam_1[[q]][3])+dis_f*true_y
            y_stack<-rbind(y_stack,qvalue) ## y stack
            
          }
          
        }
        ######## feed forward xstack 
        qn1<-nn.ff(qn1,x_stack)
        
        ####### error
        qn1$e<- (y_stack)-qn1$post[[length(qn1$size)]] 
        
        ####### back propagation
        qn1<-nn.bp(qn1)  
        
        r<-r+1
        
      }
      cat("\n","DQN update")
      ad<-apply(nn.ff(qn1,diag(state_size))$post[[length(qn1$size)]],1,which.max);ad
      q_table[[r]]<-matrix(action[ad],ncol=sqrt(state_size),byrow=T)
      print(matrix(action[ad],ncol=(sqrt(state_size)),byrow=T))

      target_qn<-qn1
      
    }
    
 
  
  
  
}








