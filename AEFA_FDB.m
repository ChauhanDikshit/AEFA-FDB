function [Fbest,Lbest,BestValues,MeanValues]=AEFA_FDB(func_num,N,max_it,FCheck,tag,Rpower,D)
%V:   Velocity.
%a:   Acceleration.
%Q:   Charge
%D:   Dimension of the test function.
%N:   Number of charged particles.
%X:   Position of particles.
%R:   Distance between charged particle in search space.
%lb:  lower bound of the variables
%ub:  upper bound of the variables
%Rnorm: Euclidean Norm
Rnorm=2; 
% Lower and upper bounds of the variables
lb=-100;ub=100;

%------------------------------------------------------------------------------------
%% random initialization of charge population.
X=initialization(D,N,ub,lb);
%% create the best so far chart and average fitnesses chart.
BestValues=[];MeanValues=[];

V=zeros(N,D);

%-------------------------------------------------------------------------------------
for iteration=1:max_it

    %% Evaluation of fitness values of charged particles.
    for i=1:N
        fitness(i)=cec14_func(X(i,:)',func_num);
    end

    if tag==1
        [best, best_X]=min(fitness); %minimization.
    else
        [best, best_X]=max(fitness); %maximization.
    end
    if iteration==1
        Fbest=best;Lbest=X(best_X,:);
    end
    if tag==1
        if best<Fbest  %minimization.
            Fbest=best;Lbest=X(best_X,:);
        end
    else
        if best>Fbest  %maximization
            Fbest=best;Lbest=X(best_X,:);
        end
    end
    for i=1:N
        Gbest(i,:)=Lbest;
    end
    BestValues=[BestValues Fbest];
    MeanValues=[MeanValues mean(fitness)];

    %-----------------------------------------------------------------------------------
    % Charge
    Fmax=max(fitness); Fmin=min(fitness); Fmean=mean(fitness);

    if Fmax==Fmin
        M=ones(N,1);
        Q=ones(N,1);
    else

        if tag==1 %for minimization
            best=Fmin;worst=Fmax;

        else %for maximization

            best=Fmax;worst=Fmin;
        end

        Q=exp((fitness-worst)./(best-worst));

    end
    Q=Q./sum(Q);
    %----------------------------------------------------------------------------------
    fper=3; %In the last iteration, only 2-6 percent of charges apply force to the others.
    %----------------------------------------------------------------------------------
    %% total electric force calculation
    l=fitnessDistanceBalance(X,fitness,iteration,max_it);
    if FCheck==1
        cbest=fper+(1-iteration/max_it)*(100-fper);
        cbest=round(N*cbest/100);
    else
        cbest=N;
    end
    [Qs s]=sort(Q,'descend');
    for i=1:N
        E(i,:)=zeros(1,D);
        for ii=1:cbest
            j=s(ii);
            if j~=i
                R=norm(X(i,:)-X(j,:),Rnorm); %Euclidian distanse.
                for k=1:D
                    E(i,k)=E(i,k)+ rand.*(Q(j))*((X(j,k)-X(i,k))/(R^Rpower+eps));

                end
            end
        end
    end
    %----------------------------------------------------------------------------------
    alpha=30;K0=500;
    K2(iteration)=K0*exp(-alpha*iteration/max_it);
    %----------------------------------------------------------------------------------
    %% Calculation of accelaration.
    a=K2(iteration)*E;
    %% Gbest-guide
    C1= (-2*(iteration^3)/(max_it^3))+2.5;
    C2=0.5+(2*(iteration^3)/(max_it^3));
    ps= (-0.39*(iteration)/(max_it))+0.5;
    wmax=0.9;wmin=0.2;p=0.25;
    w=(wmax-wmin).*(iteration/max_it)^p+wmin;
    if rand>ps
        V=w.*V+C1.*rand(N,D).*a+C2.*rand(N,D).*(Gbest-X);
    else
        V=w.*V+C1.*rand(N,D).*a+C2.*rand(N,D).*(repmat(X(l,:),N,1)-X);
    end
    X=X+V;
    X=max(X,lb);
    X=min(X,ub);

end

end