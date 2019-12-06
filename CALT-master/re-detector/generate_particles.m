 function [ contexts ] = generate_particles(pos,target_sz,param)
particles = repmat([pos target_sz]',[1 param.numParticles]);
n = size(particles,2);
if n==0
    contexts{1}.pos=pos;
    contexts{1}.target_sz=target_sz;
    return
end
sigma = particles([3,4,3,4],:);
sigma(3:4,:) = repmat(sqrt(sum(sigma(3:4,:).^2,1)), [2,1]);
par = particles + randn(4,n).*sigma;
par(3:4,:)=particles(3:4,:);
for i=1:n
    contexts{i}.pos=round(par(1:2,i)');
    contexts{i}.target_sz=round(par(3:4,i)');
end
   contexts{n+1}.pos=pos;
    contexts{n+1}.target_sz=target_sz;
end