      program pcg

      parameter (Nx=100,Ny=100)

      include 'TOTAL'

c     A simple Nx x Ny JPCG iteration for Poisson solves in 2D

      real*4 tarray(2)
      real*4 etime,t0,t1,s0,s1

      real u(0:Nx,0:Ny),f(0:Nx,0:Ny),r(0:Nx,0:Ny)
      real w(0:Nx,0:Ny),p(0:Nx,0:Ny),z(0:Nx,0:Ny)
      real Lx,Ly

      call comm_setup
      call setup_par_domains(x0,Lx,y0,Ly,NNx,NNy,Nx,Ny)

      nb = (Nx+1)*(Ny+1);

      call rzero(u,nb)
      call rone (f,nb)
      maxit = 5000
      tol   = 1.e-6

      t0 = etime(tarray)
      call jpcg_solve(u,f,Nx,Ny,x0,Lx,y0,Ly,maxit,tol,r,p,w,z)
      t1 = etime(tarray)

      elapsed = t1-t0
      flops   = maxit*((Nx-1)*(Ny-1)*20.0)
      gflops  = 1.e-9*(flops/elapsed)

      if (nio.eq.0) write(6,2) maxit,NNx,NNy,elapsed,gflops,tol
    2 format(//,3i9,1p3e19.9)

      nx1 = Nx+1
      ny1 = Ny+1
c     call outmat(u,Nx1,Ny1,'soln  ',maxit)

      call comm_finalize
      stop
      end
c-----------------------------------------------------------------------
      subroutine jpcg_solve(x,b,Nx,Ny,x0,Lx,y0,Ly,maxit,tol,r,p,w,z)

      include 'TOTAL'  ! Just for nio

      real x(1),b(1),r(1),p(1),w(1),z(1)
      real Lx,Ly

      nb = (Nx+1)*(Ny+1)

      dx   = Lx/Nx
      dx2i = 1./(dx*dx)
      dy   = Ly/Ny
      dy2i = 1./(dy*dy)
      D    = 2*(dx2i+dy2i)
      Dinv = 1./D

      call rzero(w,nb)
      call rzero(x,nb)
      call rzero(p,nb)
      call copy (r,b,nb)
      rho1 = 1.0

      r0   = sqrt( grid_dot_prod(r,r,Nx,Ny) )

      do iter=1,maxit

         call cmult2(z,r,Dinv,nb)         !                   n
         rho0 = rho1
         rho1 = grid_dot_prod(r,z,Nx,Ny)  !                  2n
         beta = rho1/rho0
         call add2s1(p,z,beta,nb)         !                  2n
         call update_bdry(p,Nx,Ny)
         call ax(w,p,Nx,Ny,dx2i,dy2i)     ! w = A*s          7n
         gamma = grid_dot_prod(w,p,Nx,Ny) !                  2n
         alpha = rho1/gamma
         alphm = -alpha
         call add2s2(x,p,alpha,nb)        ! x = x + alpha*p  2n
         call add2s2(r,w,alphm,nb)        ! r = r - alpha*p  2n
         rel2 = sqrt( grid_dot_prod(r,r,Nx,Ny) ) / r0 !      2n
         if (rel2.le.tol) goto 100
c        if (nio.eq.0) write(6,2) iter,Nx,Ny,rel2,r0      ! 20n
    2    format(3i9,1p2e19.9)
      enddo

      iter = iter-1

  100 continue

      tol   = rel2
      maxit = iter

      return
      end
c-----------------------------------------------------------------------
      subroutine copy(a,b,n)
      real a(1),b(1)
      do i = 1, n
         a(i) = b(i)
      enddo
      end
c-----------------------------------------------------------------------
      subroutine rzero(a,n)
      real a(1)
      do i = 1, n
         a(i) = 0.0
      enddo
      end
c-----------------------------------------------------------------------
      subroutine rone(a,n)
      real a(1)
      do i = 1, n
         a(i) = 1.0
      enddo
      return
      end
c-----------------------------------------------------------------------
      subroutine outmat(a,m,n,name6,ie)
      real a(m,n)
      character*6 name6
c
      write(6,*) 
      write(6,*) ie,' matrix: ',name6,m,n
      n12 = min(n,12)
      do i=1,m
         write(6,6) ie,name6,(a(i,j),j=1,n12)
      enddo
    6 format(i3,1x,a6,12f9.5)
      write(6,*) 
      return
      end
c-----------------------------------------------------------------------
      subroutine cmult2(x,y,a,n)

      real x(n), y(n)
      do i=1,n
         x(i) = a*y(i)
      enddo
      return
      end
c-----------------------------------------------------------------------
      subroutine add2s1(x,y,a,n)

      real x(n), y(n)
      do i=1,n
         x(i) = a*x(i) + y(i)
      enddo
      return
      end
c-----------------------------------------------------------------------
      subroutine add2s2(x,y,a,n)

      real x(n), y(n)
      do i=1,n
         x(i) = x(i) + a*y(i)
      enddo
      return
      end
c-----------------------------------------------------------------------
      subroutine ax(w,p,Nx,Ny,dx2i,dy2i)  ! w = A*s

      real w(0:Nx,0:Ny),p(0:Nx,0:Ny)

      diag = 2*(dx2i+dy2i)

      do j=1,Ny-1
      do i=1,Nx-1
         w(i,j) = diag*p(i,j)
     $          - ( dx2i*(p(i-1,j)+p(i+1,j))+dy2i*(p(i,j-1)+p(i,j+1)) )
      enddo
      enddo
      return
      end
c-----------------------------------------------------------------------
      function glsc2(x,y,n)

C     inner-product in double precision

      real x(1), y(1)
      real tmp,work


      tmp=0.0
      do i=1,n
         tmp = tmp+ x(i)*y(i)
      enddo

      call gop(tmp,work,'+  ',1)

      glsc2 = tmp
      return
      end
c-----------------------------------------------------------------------
      function grid_dot_prod(x,y,Nx,Ny)  ! w = A*s

      real x(0:Nx,0:Ny),y(0:Nx,0:Ny),tmp,work

      include 'TOTAL'


      tmp = 0.0
      do j=1,Ny-1
      do i=1,Nx-1
         tmp = tmp +x(i,j)*y(i,j)
      enddo
      enddo

      call gop(tmp,work,'+  ',1)
      grid_dot_prod = tmp

      return
      end
c-----------------------------------------------------------------------
      subroutine setup_par_domains(x0,Lx,y0,Ly,NNx,NNy,Nx,Ny)

c     Nx,Ny are per-rank.  Unit square globally; Lx,Ly are local spans,
c     chosen so that dx = Lx/Nx = 1/NNx in jpcg_solve.

      include 'TOTAL'

      real Lx,Ly

      NNx = np*(Nx-1)+1
      NNy = nq*(Ny-1)+1
      Lx  = (1.0*Nx)/NNx
      Ly  = (1.0*Ny)/NNy
      x0  = (1.0*pid*(Nx-1))/NNx
      y0  = (1.0*qid*(Ny-1))/NNy

      return
      end
c-----------------------------------------------------------------------
      subroutine update_bdry(u,Nx,Ny)

      include 'TOTAL'

      real u(0:Nx,0:Ny)

      parameter (Mx=1000,My=1000)
      real buf_right(My), sbuf_right(My)
      real buf_left (My), sbuf_left (My)
      real buf_bot  (Mx), sbuf_bot  (Mx)
      real buf_top  (Mx), sbuf_top  (Mx)

      if (Nx.gt.Mx) write(6,*) nid,nx,mx,' nx too large'
      if (Ny.gt.My) write(6,*) nid,ny,my,' ny too large'
      if (Nx.gt.Mx) call comm_finalize
      if (Ny.gt.My) call comm_finalize

c     call limchk(My,Ny,' Ny too large in update_bdry$')
c     call limchk(Mx,Nx,' Nx too large in update_bdry$')


c     y ^
c       |
c       | (0,2)   (1,2)   (2,2)
c       | (0,1)   (p,q)   (2,1)
c       | (0,0)   (1,0)   (2,0)   (pid,qid) = (:,0)
c       +------------------------> x

      if (pid.eq.0) then  ! LEFT SIDE
         do j=0,Ny
            u(0,j) = 0
         enddo
      else
         neigh_left = nid_pq(pid-1,qid,np)
         ircv_left  = irecv(neigh_left,buf_left,wdsize*(Ny-1))
      endif

      if (pid.eq.np-1) then  ! RIGHT SIDE
         do j=0,Ny
            u(Nx,j) = 0
         enddo
      else
         neigh_right = nid_pq(pid+1,qid,np)
         ircv_right  = irecv(neigh_right,buf_right,wdsize*(Ny-1))
      endif

      if (qid.eq.0) then ! BOTTOM
         do j=0,Nx
            u(j,0) = 0
         enddo
      else
         neigh_bot = nid_pq(pid,qid-1,np)
         ircv_bot  = irecv(neigh_bot,buf_bot,wdsize*(Nx-1))
      endif

      if (qid.eq.nq-1) then ! TOP
         do j=0,Nx
            u(j,Ny) = 0
         enddo
      else
         neigh_top = nid_pq(pid,qid+1,np)
         ircv_top  = irecv(neigh_top,buf_top,wdsize*(Nx-1))
      endif

c     POST SENDS

      if (pid.gt.0) then  ! LEFT SIDE
         do j=1,Ny-1
            sbuf_left(j) = u(1,j)
         enddo
         neigh_left = nid_pq(pid-1,qid,np)
         isnd_left  = isend(nid,sbuf_left,wdsize*(Ny-1),neigh_left,0)
      endif

      if (pid.lt.np-1) then  ! RIGHT SIDE
         do j=1,Ny-1
            sbuf_right(j) = u(Nx-1,j)
         enddo
         neigh_right = nid_pq(pid+1,qid,np)
         isnd_right  = isend(nid,sbuf_right,wdsize*(Ny-1),neigh_right,0)
      endif

      if (qid.gt.0) then ! BOTTOM
         do i=1,Nx-1
            sbuf_bot(i) = u(i,1)
         enddo
         neigh_bot = nid_pq(pid,qid-1,np)
         isnd_bot  = isend(nid,sbuf_bot,wdsize*(Nx-1),neigh_bot,0)
      endif

      if (qid.lt.nq-1) then ! TOP
         do i=1,Nx-1
            sbuf_top(i) = u(i,Ny-1)
         enddo
         neigh_top = nid_pq(pid,qid+1,np)
         isnd_top  = isend(nid,sbuf_top,wdsize*(Nx-1),neigh_top,0)
      endif

c     UNPACK RECEIVES


      if (pid.gt.0) then  ! LEFT SIDE
         call msgwait(ircv_left)
         do j=1,Ny-1
            u(0,j)= buf_left(j)
         enddo
      endif

      if (pid.lt.np-1) then  ! RIGHT SIDE
         call msgwait(ircv_right)
         do j=1,Ny-1
            u(Nx,j)=buf_right(j)
         enddo
      endif

      if (qid.gt.0) then ! BOTTOM
         call msgwait(ircv_bot)
         do i=1,Nx-1
            u(i,0)= buf_bot(i)
         enddo
      endif

      if (qid.lt.nq-1) then ! TOP
         call msgwait(ircv_top)
         do i=1,Nx-1
            u(i,Ny) = buf_top(i)
         enddo
      endif

c     CLEAR sends

      if (pid.gt.0)    call msgwait(isnd_left)
      if (pid.lt.np-1) call msgwait(isnd_right)
      if (qid.gt.0)    call msgwait(isnd_bot)
      if (qid.lt.nq-1) call msgwait(isnd_top)

      return
      end
c-----------------------------------------------------------------------
